import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/config/notification_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_refresh.dart';
import '../../../core/notifications/local_notification_helper.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/date_utils.dart';
import '../../widgets/widget_data_sync.dart';
import '../models/notification_item.dart';
import 'polling_background_store.dart';

/// Eindeutiger Name des periodischen WorkManager-Fallbacks (15 Min).
const backgroundPollingTaskName = 'sinclear_notification_poll';

/// Höchstzahl lokal angezeigter Benachrichtigungen pro Poll. Bei einem
/// Erstabruf ohne Cursor kann die API bis zu 50 ungelesene Einträge liefern —
/// die würden den Benachrichtigungs-Shade sonst fluten.
const _maxShownPerPoll = 5;

/// WorkManager-Einstiegspunkt. Muss eine Top-Level-Funktion mit
/// `vm:entry-point` sein, damit sie im Hintergrund-Isolate aufrufbar ist.
@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundPollingTaskName) {
      await pollNotificationsHeadless();
    }
    return true;
  });
}

/// Initialisiert WorkManager einmalig (Android). Auf Web/Desktop ein No-op.
Future<void> initBackgroundPolling() async {
  if (kIsWeb || !Platform.isAndroid) return;
  await Workmanager().initialize(workmanagerCallbackDispatcher);
}

/// Registriert den periodischen Fallback (15 Minuten).
///
/// Läuft nur, wenn der Foreground-Service nicht (frisch) aktiv ist — siehe
/// [PollingBackgroundStore.foregroundAlive].
Future<void> registerBackgroundPolling() async {
  if (kIsWeb || !Platform.isAndroid) return;
  await Workmanager().registerPeriodicTask(
    backgroundPollingTaskName,
    backgroundPollingTaskName,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

/// Entfernt den periodischen Fallback wieder.
Future<void> cancelBackgroundPolling() async {
  if (kIsWeb || !Platform.isAndroid) return;
  await Workmanager().cancelByUniqueName(backgroundPollingTaskName);
}

/// Ein einzelner Hintergrund-Poll: Token auffrischen, ungelesene
/// Benachrichtigungen seit dem letzten Cursor laden und lokal anzeigen.
///
/// Bewusst ohne Content-Enrichment (`NotificationContentResolver`): Im
/// Hintergrund-Isolate stehen die App-Services nicht zur Verfügung. Die API
/// liefert `title`/`text` direkt; fehlen sie, greift der lokale
/// `NotificationTypeLabel`-Fallback (siehe AGENTS.md).
///
/// `ponytail:` Der Access-Token-Refresh ist hier minimal dupliziert (statt
/// `AuthService` wiederzuverwenden, der im Hintergrund-Isolate nicht existiert).
/// Upgrade: gemeinsamer Refresh-Helper in `core/`.
Future<bool> pollNotificationsHeadless({bool force = false}) async {
  if (kIsWeb) return false;

  try {
    final store = PollingBackgroundStore();
    if (!force && await store.foregroundAlive()) {
      // Der Foreground-Service pollt bereits und ist frisch.
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('api_base_url');
    if (baseUrl == null) return false;

    final api = ApiClient(baseUrl: baseUrl);
    try {
      final storage = TokenStorage();
      final ok = await runHeadlessPoll(
        api: api,
        storage: storage,
        store: store,
      );
      // Widget-Daten im selben Poll aktualisieren (kein eigener Worker).
      await syncWidgetsHeadless(api: api, storage: storage);
      return ok;
    } finally {
      api.dispose();
    }
  } catch (e, st) {
    developer.log(
      'Headless notification poll failed',
      error: e,
      stackTrace: st,
      name: 'background_poller',
    );
    return false;
  }
}

/// Kern des Hintergrund-Polls mit injizierten Abhängigkeiten (testbar).
///
/// Der Access-Token-Refresh liegt im gemeinsamen Helfer
/// `core/network/token_refresh.dart`, da auch die Widget-Synchronisation
/// ihn im Hintergrund-Isolate braucht.
@visibleForTesting
Future<bool> runHeadlessPoll({
  required ApiClient api,
  required TokenStorage storage,
  required PollingBackgroundStore store,
}) async {
  final accessToken = await refreshAccessToken(api, storage);
  if (accessToken == null) return false;

  final cursor = await store.lastSeen();
  final response = await api.get(
    '/notifications',
    queryParams: cursor != null ? {'since': cursor} : null,
    token: accessToken,
  );

  final list = response['notifications'] as List? ?? const [];
  if (list.isEmpty) return true;

  final items = list
      .map((json) => NotificationItem.fromJson(json as Map<String, dynamic>))
      .toList();

  await LocalNotificationHelper.init();
  for (final item in items.take(_maxShownPerPoll)) {
    await LocalNotificationHelper.show(
      id: stableNotificationId(item.id),
      title: _title(item),
      body: _body(item),
      payload: jsonEncode(item.toJson()),
    );
  }

  await store.setLastSeen(
    toApiDate(items.first.createdAt, withMilliseconds: true),
  );
  return true;
}

String _title(NotificationItem item) {
  final title = item.title;
  if (title != null && title.isNotEmpty) return title;
  return NotificationTypeLabel.title(item.type);
}

String _body(NotificationItem item) {
  final text = item.text;
  if (text != null && text.isNotEmpty) return text;
  return NotificationTypeLabel.fallbackBody(item.type);
}

/// Deterministische, prozessübergreifend stabile Benachrichtigungs-ID aus der
/// Notification-ID (FNV-1a 32 Bit). `String.hashCode` ist nicht über Prozesse
/// hinweg garantiert — ein erneutes Anzeigen derselben Benachrichtigung würde
/// sonst ein zweites Mal erscheinen, statt die bestehende zu aktualisieren.
int stableNotificationId(String id) {
  var hash = 0x811c9dc5;
  for (final unit in id.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
