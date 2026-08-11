import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static void Function(String? payload)? _onTap;

  static const _channelId = 'sinclear_main';
  static const _channelName = 'Sinclear Benachrichtigungen';

  /// Einmalige Initialisierung. Muss nach [setNotificationTapHandler]
  /// aufgerufen werden, damit der Handler auch Cold-Starts abfängt.
  static Future<bool> init() async {
    if (kIsWeb || _initialized) return false;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    final result = await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleResponse,
    );
    _initialized = result ?? false;
    if (_initialized) await _checkAppLaunchDetails();
    return _initialized;
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb || !_initialized) return false;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb || !_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Registriert den Tap-Handler. Muss vor [init] aufgerufen werden, damit
  /// ein Kaltstart (App wurde durch die Notification gestartet) erkannt wird.
  static void setNotificationTapHandler(void Function(String? payload) onTap) {
    _onTap = onTap;
    if (kIsWeb || !_initialized) return;
    _checkAppLaunchDetails();
  }

  static void _handleResponse(NotificationResponse response) {
    _onTap?.call(response.payload);
  }

  static Future<void> _checkAppLaunchDetails() async {
    final onTap = _onTap;
    if (onTap == null) return;

    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      onTap(details!.notificationResponse?.payload);
    }
  }
}
