import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'background_poller.dart';
import 'polling_background_store.dart';

/// Stabile ID der dauerhaften Foreground-Service-Benachrichtigung.
const _serviceId = 4201;

/// Intervall des Hintergrund-Pollings im Foreground-Service.
const pollingForegroundInterval = Duration(minutes: 5);

/// Steuert den Android-Foreground-Service, der Beyond im Hintergrund am Leben
/// hält und alle [pollingForegroundInterval] Minuten pollt.
///
/// Läuft der Service nicht (Dismiss, Timeout, Rechte-Entzug), übernimmt der
/// periodische WorkManager-Fallback (siehe [registerBackgroundPolling]).
class ForegroundPollingService {
  final PollingBackgroundStore _store;
  bool _initialized = false;
  bool _active = false;

  ForegroundPollingService({PollingBackgroundStore? store})
    : _store = store ?? PollingBackgroundStore();

  /// `true`, wenn der Service in dieser Sitzung erfolgreich gestartet wurde.
  bool get isActive => _active;

  /// Initialisiert Notification-Kanal, Task-Optionen und den
  /// Kommunikations-Port. Idempotent; auf Web/Desktop ein No-op.
  void initialize() {
    if (kIsWeb || !Platform.isAndroid || _initialized) return;
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'sinclear_polling',
        channelName: 'Hintergrund-Aktualisierung',
        channelDescription:
            'Hält Beyond aktiv, damit Benachrichtigungen ankommen.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          pollingForegroundInterval.inMilliseconds,
        ),
        allowWakeLock: true,
        allowAutoRestart: true,
      ),
    );
    _initialized = true;
  }

  /// Startet den Service und registriert den WorkManager-Fallback.
  ///
  /// Liefert `false`, wenn die Benachrichtigungs-Berechtigung fehlt — ohne sie
  /// kann der Service keine dauerhafte Benachrichtigung anzeigen. Mit
  /// [requestPermission] `false` (Cold-Start) wird nur geprüft, nie gefragt.
  Future<bool> start({bool requestPermission = true}) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    initialize();
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await _store.touchHeartbeat();
        await _store.setForegroundActive(true);
        await registerBackgroundPolling();
        _active = true;
        return true;
      }

      final permission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (permission != NotificationPermission.granted) {
        if (!requestPermission) return false;
        final requested =
            await FlutterForegroundTask.requestNotificationPermission();
        if (requested != NotificationPermission.granted) return false;
      }

      await _store.touchHeartbeat();
      await _store.setForegroundActive(true);
      final result = await FlutterForegroundTask.startService(
        serviceId: _serviceId,
        notificationTitle: 'Beyond-Benachrichtigungen aktiv',
        notificationText: 'Tippe, um die App zu öffnen.',
        callback: startPollingTask,
      );
      await registerBackgroundPolling();
      _active = result is ServiceRequestSuccess;
      return _active;
    } catch (e, st) {
      developer.log(
        'Failed to start foreground polling service',
        error: e,
        stackTrace: st,
        name: 'foreground_polling',
      );
      await _store.setForegroundActive(false);
      _active = false;
      return false;
    }
  }

  /// Stoppt den Service und räumt Flag und Fallback auf.
  Future<void> stop() async {
    if (kIsWeb || !Platform.isAndroid) return;
    _active = false;
    await _store.setForegroundActive(false);
    await cancelBackgroundPolling();
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e, st) {
      developer.log(
        'Failed to stop foreground polling service',
        error: e,
        stackTrace: st,
        name: 'foreground_polling',
      );
    }
  }

  /// Stoppt den Service und verwirft den geteilten Cursor (Logout).
  Future<void> reset() async {
    await stop();
    await _store.reset();
  }
}

/// Top-Level-Callback des Foreground-Service; läuft im Hintergrund-Isolate.
@pragma('vm:entry-point')
void startPollingTask() {
  FlutterForegroundTask.setTaskHandler(_PollingTaskHandler());
}

/// Der periodische Task des Foreground-Service (5 Min).
class _PollingTaskHandler extends TaskHandler {
  final PollingBackgroundStore _store = PollingBackgroundStore();

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _store.setForegroundActive(true);
    await _store.touchHeartbeat(timestamp);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_store.touchHeartbeat(timestamp));
    unawaited(pollNotificationsHeadless(force: true));
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _store.setForegroundActive(false);
  }

  @override
  void onNotificationDismissed() {
    unawaited(_store.setForegroundActive(false));
  }
}
