import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_utils.dart';
import '../models/notification_item.dart';

/// Persistenter Zustand für Benachrichtigungen und das Hintergrund-Polling.
///
/// Teilt den `since`-Cursor sowie das Set bereits angezeigter
/// Benachrichtigungen (`notified_ids`) zwischen In-App-Polling,
/// Foreground-Service, WorkManager-Fallback, UnifiedPush und FCM-Wakeup.
/// Vor jedem Lesezugriff wird [SharedPreferences.reload] ausgeführt, damit
/// Änderungen aus anderen Dart-Isolates (WorkManager, ForegroundTask, FCM
/// Background-Handler) sofort sichtbar sind und Benachrichtigungen niemals
/// mehrfach als System-Banner erscheinen.
class PollingBackgroundStore {
  static const _lastSeenKey = 'notification_last_seen';
  static const _notifiedIdsKey = 'notification_notified_ids';
  static const _foregroundActiveKey = 'polling_foreground_active';
  static const _heartbeatKey = 'polling_foreground_heartbeat';
  static const _setupCompletedKey = 'notification_setup_completed';

  /// Maximale Anzahl gemerkter Notification-Schlüssel im Ringpuffer.
  static const _maxNotifiedIds = 200;

  /// Zeitpunkt des letzten Heartbeats, ab dem der Foreground-Service als
  /// tot gilt, obwohl das Flag noch gesetzt ist.
  static const foregroundStaleAfter = Duration(minutes: 15);

  Future<SharedPreferences> _reloadedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.reload();
    } catch (_) {
      // In Tests oder auf Plattformen ohne nativen Kanal kann reload()
      // fehlschlagen; der In-Memory-Stand bleibt dann gültig.
    }
    return prefs;
  }

  /// Eindeutiger Dedupe-Schlüssel einer Benachrichtigungs-Version.
  ///
  /// Kombiniert `id` und `createdAt` (mit Millisekunden), damit gebündelte
  /// Benachrichtigungen (`coalescedUpsert`, z. B. Chat mit aktualisiertem
  /// `createdAt`) bei einer echten neuen Nachricht wieder angezeigt werden,
  /// unveränderte Benachrichtigungen aber nie doppelt erscheinen.
  static String dedupeKeyFor(NotificationItem item) =>
      '${item.id}@${toApiDate(item.createdAt, withMilliseconds: true)}';

  /// Letzter bekannter `since`-Cursor (API-Format), oder `null`.
  Future<String?> lastSeen() async =>
      (await _reloadedPrefs()).getString(_lastSeenKey);

  /// Speichert [value] als neuen `since`-Cursor, sofern er neuer als der
  /// bisher gespeicherte Cursor ist (verhindert Rückwärtssprünge bei
  /// konkurrierenden Isolates).
  Future<void> setLastSeen(String value) async {
    final prefs = await _reloadedPrefs();
    final current = prefs.getString(_lastSeenKey);
    if (current != null && current.compareTo(value) > 0) return;
    await prefs.setString(_lastSeenKey, value);
  }

  /// Prüft, ob [item] bereits als lokale Benachrichtigung angezeigt wurde.
  Future<bool> wasShown(NotificationItem item) async {
    final prefs = await _reloadedPrefs();
    final list = prefs.getStringList(_notifiedIdsKey) ?? const [];
    final key = dedupeKeyFor(item);
    return list.contains(key) || list.contains(item.id);
  }

  /// Markiert [item] persistent als angezeigt.
  ///
  /// Liefert `true`, wenn [item] **neu** ist (noch nicht angezeigt wurde),
  /// und `false`, wenn es bereits zuvor angezeigt wurde (Duplikat).
  Future<bool> markAsShown(NotificationItem item) async {
    final prefs = await _reloadedPrefs();
    final list = List<String>.from(
      prefs.getStringList(_notifiedIdsKey) ?? const [],
    );
    final key = dedupeKeyFor(item);
    if (list.contains(key) || list.contains(item.id)) {
      return false;
    }
    list.add(key);
    if (list.length > _maxNotifiedIds) {
      list.removeRange(0, list.length - _maxNotifiedIds);
    }
    await prefs.setStringList(_notifiedIdsKey, list);
    return true;
  }

  /// Filtert [items] auf diejenigen, die noch nie als System-Benachrichtigung
  /// angezeigt wurden, und markiert sie in einem Schritt persistent als
  /// angezeigt.
  Future<List<NotificationItem>> filterAndMarkNew(
    Iterable<NotificationItem> items,
  ) async {
    final prefs = await _reloadedPrefs();
    final list = List<String>.from(
      prefs.getStringList(_notifiedIdsKey) ?? const [],
    );
    final known = list.toSet();
    final fresh = <NotificationItem>[];

    for (final item in items) {
      final key = dedupeKeyFor(item);
      if (known.contains(key) || known.contains(item.id)) continue;
      known.add(key);
      list.add(key);
      fresh.add(item);
    }

    if (fresh.isNotEmpty) {
      if (list.length > _maxNotifiedIds) {
        list.removeRange(0, list.length - _maxNotifiedIds);
      }
      await prefs.setStringList(_notifiedIdsKey, list);
    }

    return fresh;
  }

  /// `true`, wenn der Foreground-Service zuletzt als laufend markiert wurde.
  Future<bool> foregroundActive() async =>
      (await _reloadedPrefs()).getBool(_foregroundActiveKey) ?? false;

  Future<void> setForegroundActive(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(
        _foregroundActiveKey,
        value,
      );

  /// Auffrischung, die der Foreground-Service bei jedem Poll sendet.
  Future<void> touchHeartbeat([DateTime? now]) async {
    final millis = (now ?? DateTime.now()).millisecondsSinceEpoch;
    await (await SharedPreferences.getInstance()).setInt(_heartbeatKey, millis);
  }

  /// `true`, wenn der Foreground-Service laut Flag aktiv ist und sein
  /// Heartbeat nicht älter als [foregroundStaleAfter] ist.
  ///
  /// `ponytail:` Der Heartbeat ist eine Heuristik — stirbt der Prozess ohne
  /// `onDestroy`, hält der Fallback für höchstens 15 Minuten still. Upgrade:
  /// `FlutterForegroundTask.isRunningService` direkt im WorkManager-Isolate.
  Future<bool> foregroundAlive() async {
    final prefs = await _reloadedPrefs();
    if (!(prefs.getBool(_foregroundActiveKey) ?? false)) return false;
    final millis = prefs.getInt(_heartbeatKey);
    if (millis == null) return false;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(millis),
    );
    return age < foregroundStaleAfter;
  }

  /// `true`, wenn das Benachrichtigungs-Setup auf diesem Gerät bereits
  /// einmal erfolgreich ausgeführt wurde (nur Android relevant).
  Future<bool> notificationSetupCompleted() async =>
      (await _reloadedPrefs()).getBool(_setupCompletedKey) ?? false;

  Future<void> setNotificationSetupCompleted(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(
        _setupCompletedKey,
        value,
      );

  /// Setzt Flag, Heartbeat, Cursor, gesehene IDs und Setup-Status zurück
  /// (Logout).
  Future<void> reset() async {
    final prefs = await _reloadedPrefs();
    await prefs.remove(_lastSeenKey);
    await prefs.remove(_notifiedIdsKey);
    await prefs.remove(_foregroundActiveKey);
    await prefs.remove(_heartbeatKey);
    await prefs.remove(_setupCompletedKey);
  }
}
