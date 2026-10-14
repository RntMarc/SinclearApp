import 'dart:convert';
import 'dart:developer' as developer;

import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../../core/network/api_client.dart';
import '../../core/network/token_refresh.dart';
import '../../core/services/time_zone_service.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/date_utils.dart';
import '../../design/theme/design_preferences.dart';
import '../calendar/models/calendar_models.dart';
import '../notifications/models/notification_item.dart';
import '../travel/models/travel_models.dart';
import 'widget_payloads.dart';
import 'widget_theme.dart';

/// Voll qualifizierte Klassennamen der drei Glance-Widget-Receiver.
const _activityProvider = 'de.sinclear.beyond.widgets.ActivityWidgetReceiver';
const _todayProvider = 'de.sinclear.beyond.widgets.TodayWidgetReceiver';
const _tripProvider = 'de.sinclear.beyond.widgets.TripWidgetReceiver';

/// Data-Keys unter `HomeWidgetPreferences` (nativ via
/// `HomeWidgetPlugin.getData` gelesen).
const _keyActivity = 'activity';
const _keyToday = 'today';
const _keyTrip = 'trip';
const _keyTheme = 'theme';

/// Mindestabstand zwischen zwei Widget-Synchronisationen. Das
/// Benachrichtigungs-Polling läuft alle 5 Min; Kalender/Reisen ändern sich
/// selten — der Abstand hält Akku- und API-Last gering.
const Duration _minSyncInterval = Duration(minutes: 15);
const String _keyLastSync = 'beyond.widget_sync_last';

/// Aktualisiert alle drei Widgets aus der API — läuft sowohl im
/// Haupt-Isolate (App aktiv) als auch im Hintergrund-Polling-Isolate.
///
/// Erzeugt keinen eigenen Worker, sondern wird vom bestehenden
/// Benachrichtigungs-Polling (Foreground-Service/WorkManager) und beim
/// Verlassen der App angestoßen. Der Aufrufer bleibt Eigentümer von [api].
Future<void> syncWidgetsHeadless({
  required ApiClient api,
  required TokenStorage storage,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final last = prefs.getInt(_keyLastSync) ?? 0;
    if (nowMs - last < _minSyncInterval.inMilliseconds) return;

    final token = await refreshAccessToken(api, storage);
    if (token == null) return;

    // Zeitzonen-Datenbank laden, damit `instantToWallTime`/`formatTimeInZone`
    // im Hintergrund-Isolate korrekt auflösen (kein TimeZoneService dort).
    tzdata.initializeTimeZones();
    final timezone = await _storedTimezone();
    final now = DateTime.now();

    final unread = await _fetchUnread(api, token);
    final today = await _fetchToday(api, token, timezone, now);
    final trips = await _fetchTrips(api, token);

    final variant = await DesignPreferences.load();
    final customAccent = await DesignPreferences.loadCustomAccent();
    final theme = WidgetTheme.fromVariant(variant, customAccent: customAccent);

    await Future.wait(<Future<dynamic>>[
      HomeWidget.saveWidgetData<String>(
        _keyActivity,
        jsonEncode(ActivityPayload.fromUnread(unread).toJson()),
      ),
      HomeWidget.saveWidgetData<String>(
        _keyToday,
        jsonEncode(TodayPayload.fromEntries(today).toJson()),
      ),
      HomeWidget.saveWidgetData<String>(
        _keyTrip,
        jsonEncode(TripPayload.fromTrips(trips, now).toJson()),
      ),
      HomeWidget.saveWidgetData<String>(_keyTheme, jsonEncode(theme.toJson())),
    ]);

    await Future.wait(<Future<dynamic>>[
      HomeWidget.updateWidget(qualifiedAndroidName: _activityProvider),
      HomeWidget.updateWidget(qualifiedAndroidName: _todayProvider),
      HomeWidget.updateWidget(qualifiedAndroidName: _tripProvider),
    ]);

    // Erst nach erfolgreichem Durchlauf den Zeitstempel setzen, damit ein
    // fehlgeschlagener Sync beim nächsten Poll (5 Min) erneut versucht wird.
    await prefs.setInt(_keyLastSync, nowMs);
  } catch (e, st) {
    developer.log(
      'Widget sync failed',
      error: e,
      stackTrace: st,
      name: 'widget_sync',
    );
  }
}

/// Liest die zuletzt persistierte effektive Zeitzone (Fallback UTC).
Future<String> _storedTimezone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(TimeZoneService.storedTimezoneKey) ??
      TimeZoneService.fallback;
}

Future<List<NotificationItem>> _fetchUnread(
  ApiClient api,
  String token,
) async {
  final data = await api.get('/notifications', token: token);
  final list = data['notifications'] as List? ?? const <dynamic>[];
  return list
      .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<List<CalendarEntry>> _fetchToday(
  ApiClient api,
  String token,
  String timezone,
  DateTime now,
) async {
  final todayInZone = instantToWallTime(now.toUtc(), timezone);
  final day = toApiDateOnly(todayInZone);
  final data = await api.get(
    '/calendar/all',
    queryParams: <String, String>{
      'start': day,
      'end': day,
      'timezone': timezone,
    },
    token: token,
  );
  return CalendarAllResponse.fromJson(data).data;
}

Future<List<TravelTrip>> _fetchTrips(ApiClient api, String token) async {
  final data = await api.get(
    '/trips',
    queryParams: <String, String>{'page': '1', 'limit': '20'},
    token: token,
  );
  return TravelTripListResponse.fromJson(data).data;
}
