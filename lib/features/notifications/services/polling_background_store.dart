import 'package:shared_preferences/shared_preferences.dart';

/// Persistenter Zustand für das Polling im Hintergrund.
///
/// Der `since`-Cursor wird zwischen In-App-Polling, Foreground-Service und
/// WorkManager-Fallback geteilt, damit eine Benachrichtigung nicht doppelt
/// angezeigt wird. Zusätzlich wird festgehalten, ob der Foreground-Service
/// läuft (Flag + Heartbeat), damit der WorkManager-Fallback pausiert, solange
/// der Service zuverlässig pollt.
class PollingBackgroundStore {
  static const _lastSeenKey = 'notification_last_seen';
  static const _foregroundActiveKey = 'polling_foreground_active';
  static const _heartbeatKey = 'polling_foreground_heartbeat';

  /// Zeitpunkt des letzten Heartbeats, ab dem der Foreground-Service als
  /// tot gilt, obwohl das Flag noch gesetzt ist.
  static const foregroundStaleAfter = Duration(minutes: 15);

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Letzter bekannter `since`-Cursor (API-Format), oder `null`.
  Future<String?> lastSeen() async => (await _prefs).getString(_lastSeenKey);

  Future<void> setLastSeen(String value) async =>
      (await _prefs).setString(_lastSeenKey, value);

  /// `true`, wenn der Foreground-Service zuletzt als laufend markiert wurde.
  Future<bool> foregroundActive() async =>
      (await _prefs).getBool(_foregroundActiveKey) ?? false;

  Future<void> setForegroundActive(bool value) async =>
      (await _prefs).setBool(_foregroundActiveKey, value);

  /// Auffrischung, die der Foreground-Service bei jedem Poll sendet.
  Future<void> touchHeartbeat([DateTime? now]) async {
    final millis = (now ?? DateTime.now()).millisecondsSinceEpoch;
    await (await _prefs).setInt(_heartbeatKey, millis);
  }

  /// `true`, wenn der Foreground-Service laut Flag aktiv ist und sein
  /// Heartbeat nicht älter als [foregroundStaleAfter] ist.
  ///
  /// `ponytail:` Der Heartbeat ist eine Heuristik — stirbt der Prozess ohne
  /// `onDestroy`, hält der Fallback für höchstens 15 Minuten still. Upgrade:
  /// `FlutterForegroundTask.isRunningService` direkt im WorkManager-Isolate.
  Future<bool> foregroundAlive() async {
    final prefs = await _prefs;
    if (!(prefs.getBool(_foregroundActiveKey) ?? false)) return false;
    final millis = prefs.getInt(_heartbeatKey);
    if (millis == null) return false;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(millis),
    );
    return age < foregroundStaleAfter;
  }

  /// Setzt Flag, Heartbeat und Cursor zurück (Logout).
  Future<void> reset() async {
    final prefs = await _prefs;
    await prefs.remove(_lastSeenKey);
    await prefs.remove(_foregroundActiveKey);
    await prefs.remove(_heartbeatKey);
  }
}
