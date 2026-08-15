import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../user/services/user_service.dart';
import '../models/dav_sync_notice.dart';
import '../models/dav_token_models.dart';
import 'dav_token_service.dart';

/// Ein abonnierbarer Beyond-Kalender-Typ im nativen Systemkalender.
class DavCalendarType {
  final String segment;
  final String label;
  final int color;

  const DavCalendarType({
    required this.segment,
    required this.label,
    required this.color,
  });
}

/// Flutter-seitiger Zugriff auf die native Android-CalDAV-Synchronisation.
///
/// Richtet einen App-eigenen SyncAdapter-Account ein, der die drei
/// Beyond-Kalender (Events, Reisen & Fahrten, Geburtstage) in die
/// Systemkalender-App spiegelt. Standard: aktiviert (einmalige
/// Berechtigungsanfrage), Opt-out über `disable()`.
class DavSyncService {
  static const MethodChannel _channel = MethodChannel(
    'de.sinclear.beyond/dav_sync',
  );
  static const String _promptedKey = 'dav_sync_prompted';
  static const String _segmentsKey = 'dav_sync_segments';
  static const String _noticesKey = 'dav_sync_notices';
  static const String _emailKey = 'dav_sync_email';
  static const String _syncTokenLabel = 'Android Sync';
  static const int _maxNotices = 20;

  /// Die drei Kalender-Typen der API (Segment, Anzeigename, Farbe).
  static const List<DavCalendarType> calendarTypes = [
    DavCalendarType(
      segment: 'calendar',
      label: 'Beyond Kalender',
      color: 0xFF6366F1,
    ),
    DavCalendarType(
      segment: 'travel',
      label: 'Reisen & Fahrten',
      color: 0xFFF59E0B,
    ),
    DavCalendarType(
      segment: 'birthdays',
      label: 'Geburtstage',
      color: 0xFFEC4899,
    ),
  ];

  final DavTokenService _davTokens;
  final UserService _user;
  final String apiBaseUrl;
  final SharedPreferences _prefs;

  DavSyncService({
    required this._davTokens,
    required this._user,
    required this.apiBaseUrl,
    required this._prefs,
  });

  /// Die DAV-Basis-URL liegt unter `/api/dav/`, die REST-API unter `/api/v2`.
  String get davBaseUrl => '${apiBaseUrl.replaceFirst('/api/v2', '/api/dav')}/';

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Nur auf Android verfügbar; andere Plattformen melden `false`.
  Future<bool> isEnabled() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('isEnabled') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Fordert die WRITE_CALENDAR-Laufzeitberechtigung an (System-Dialog).
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('requestCalendarPermission') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  /// Einmaliger Auto-Aktivierungsversuch nach dem ersten Login.
  ///
  /// Standard: aktiviert, sobald der Nutzer die System-Berechtigung erteilt.
  /// Besteht der Account bereits (warm start), wird nur ein Sync angestoßen
  /// bzw. bei abgelaufenem Token das Token rotiert. Ein Account, der eine
  /// Neuinstallation überlebt hat, wird mit frischen Zugangsdaten geheilt.
  Future<void> maybeAutoEnable() async {
    if (!isSupported) return;
    try {
      await _maybeAutoEnable();
    } catch (e) {
      addNotice(
        step: 'Automatische Einrichtung',
        message: _shortError(e),
        severity: DavSyncSeverity.error,
      );
    }
  }

  Future<void> _maybeAutoEnable() async {
    if (await isEnabled()) {
      // Account existiert bereits. Bei Neuinstallation ist die lokale
      // E-Mail-Marke weg, der Android-Account aber erhalten geblieben →
      // Zugangsdaten (Token, URL) neu einrichten statt blind zu synchronisieren.
      try {
        final user = await _user.getMe();
        final bound = _prefs.getString(_emailKey);
        if (bound != user.base.email) {
          await enable();
          return;
        }
      } catch (e) {
        addNotice(
          step: 'Nutzerdaten laden',
          message: _shortError(e),
          severity: DavSyncSeverity.warning,
        );
      }
      if (await lastSyncStatus() == 'auth') await enable();
      await syncNow();
      return;
    }

    final granted = await requestPermission();
    if (!granted) {
      addNotice(
        step: 'Berechtigung',
        message: 'Kalender-Zugriff wurde nicht erteilt.',
        severity: DavSyncSeverity.warning,
      );
      return;
    }

    final ok = await enable();
    if (ok) await _prefs.setBool(_promptedKey, true);
  }

  /// Erstellt (bzw. rotiert) das Sync-Token, richtet den Android-Account ein
  /// und stößt den ersten Sync an. Jeder Schritt protokolliert seinen Fehler
  /// als Hinweis (persistente Karte im DAV-Tokens-Screen).
  Future<bool> enable() async {
    if (!isSupported) return false;

    try {
      final old = await _davTokens.list();
      for (final token in old.where((t) => t.label == _syncTokenLabel)) {
        try {
          await _davTokens.delete(token.id);
        } catch (_) {
          // Alte Tokens aufräumen ist best effort.
        }
      }
    } catch (_) {
      // Tokenliste konnte nicht geladen werden; create() versucht es trotzdem.
    }

    final DavTokenCreateResult created;
    try {
      created = await _davTokens.create(_syncTokenLabel);
    } catch (e) {
      addNotice(
        step: 'Token erstellen',
        message: _shortError(e),
        severity: DavSyncSeverity.error,
      );
      return false;
    }

    final String email;
    final String userId;
    try {
      final user = await _user.getMe();
      email = user.base.email;
      userId = user.base.id;
    } catch (e) {
      addNotice(
        step: 'Nutzerdaten laden',
        message: _shortError(e),
        severity: DavSyncSeverity.error,
      );
      return false;
    }

    final segments = await enabledSegments();
    try {
      final detail = await _channel.invokeMethod<String>('enable', {
        'email': email,
        'userId': userId,
        'davBaseUrl': davBaseUrl,
        'davToken': created.token,
        'segments': segments,
      });
      if (detail == 'ok' || detail == 'account_exists') {
        await _prefs.setString(_emailKey, email);
        return true;
      }
      addNotice(
        step: 'Systemkalender-Account',
        message: _accountErrorText(detail),
        severity: DavSyncSeverity.error,
      );
      return false;
    } on PlatformException catch (e) {
      addNotice(
        step: 'Systemkalender-Account',
        message: '${e.code}: ${e.message ?? 'Unbekannter Fehler'}',
        severity: DavSyncSeverity.error,
      );
      return false;
    }
  }

  /// Persistente Hinweise zum Synchronisationsfluss (neueste zuerst).
  List<DavSyncNotice> notices() {
    final raw = _prefs.getString(_noticesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => DavSyncNotice.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Entfernt einen einzelnen Hinweis.
  void clearNotice(String id) {
    final remaining = notices().where((n) => n.id != id).toList();
    _prefs.setString(
      _noticesKey,
      jsonEncode(remaining.map((n) => n.toJson()).toList()),
    );
  }

  /// Entfernt alle Hinweise.
  void clearNotices() => _prefs.remove(_noticesKey);

  void addNotice({
    required String step,
    required String message,
    required DavSyncSeverity severity,
  }) {
    final all = notices()
      ..insert(
        0,
        DavSyncNotice(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          severity: severity,
          step: step,
          message: message,
          createdAt: DateTime.now(),
        ),
      );
    if (all.length > _maxNotices) all.removeRange(_maxNotices, all.length);
    _prefs.setString(
      _noticesKey,
      jsonEncode(all.map((n) => n.toJson()).toList()),
    );
  }

  String _shortError(Object e) {
    if (e is ApiException) {
      return 'HTTP ${e.statusCode} (${e.errorCode})';
    }
    if (e is TimeoutException) {
      return 'Zeitüberschreitung (Server nicht erreichbar)';
    }
    if (e is http.ClientException) {
      return 'Keine Verbindung zum Server';
    }
    return e.toString();
  }

  String _accountErrorText(String? detail) {
    switch (detail) {
      case 'add_account_failed':
        return 'Android-Account konnte nicht angelegt werden.';
      default:
        return 'Account-Einrichtung fehlgeschlagen ($detail).';
    }
  }

  /// Die aktuell aktivierten Kalender-Typen (lokal persistiert).
  Future<List<String>> enabledSegments() async {
    final saved = _prefs.getStringList(_segmentsKey);
    if (saved != null && saved.isNotEmpty) return saved;
    return calendarTypes.map((t) => t.segment).toList();
  }

  /// Ändert die Auswahl der Kalender-Typen und stößt einen Sync an.
  Future<void> updateSegments(List<String> segments) async {
    await _prefs.setStringList(_segmentsKey, segments);
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<bool>('updateSegments', {
        'segments': segments,
      });
    } on PlatformException {
      // Best effort; die Auswahl ist lokal gespeichert.
    }
  }

  /// Opt-out: entfernt Account und synchronisierte Daten aus dem System.
  Future<void> disable() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('disable');
    } on PlatformException {
      // Opt-out ist best effort.
    }
  }

  /// Stößt sofort einen Sync an.
  Future<void> syncNow() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('syncNow');
    } on PlatformException {
      // Best effort.
    }
  }

  /// Fehlerzustand (`auth`, `error:…`) oder letzter Sync-Zeitpunkt.
  Future<String?> lastSyncStatus() async {
    if (!isSupported) return null;
    try {
      return await _channel.invokeMethod<String>('lastSyncStatus');
    } on PlatformException {
      return null;
    }
  }
}
