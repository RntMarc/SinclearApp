import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../user/services/user_service.dart';
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
  static const String _syncTokenLabel = 'Android Sync';

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
  /// bzw. bei abgelaufenem Token das Token rotiert.
  Future<void> maybeAutoEnable() async {
    if (!isSupported) return;

    if (await isEnabled()) {
      if (await lastSyncStatus() == 'auth') await enable();
      await syncNow();
      return;
    }

    if (_prefs.getBool(_promptedKey) ?? false) return;
    _prefs.setBool(_promptedKey, true);

    if (!await requestPermission()) return;
    await enable();
  }

  /// Erstellt (bzw. rotiert) das Sync-Token, richtet den Android-Account ein
  /// und stößt den ersten Sync an.
  Future<bool> enable() async {
    if (!isSupported) return false;
    final old = await _davTokens.list();
    for (final token in old.where((t) => t.label == _syncTokenLabel)) {
      try {
        await _davTokens.delete(token.id);
      } catch (_) {
        // Alte Tokens aufräumen ist best effort.
      }
    }
    final created = await _davTokens.create(_syncTokenLabel);
    final user = await _user.getMe();
    final segments = await enabledSegments();
    try {
      return await _channel.invokeMethod<bool>('enable', {
            'email': user.base.email,
            'userId': user.base.id,
            'davBaseUrl': davBaseUrl,
            'davToken': created.token,
            'segments': segments,
          }) ??
          false;
    } on PlatformException {
      return false;
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
