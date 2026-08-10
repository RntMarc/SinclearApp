import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'sinclear_main';
  static const _channelName = 'Sinclear Benachrichtigungen';

  static Future<bool> init() async {
    if (kIsWeb || _initialized) return false;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    final result = await _plugin.initialize(initSettings);
    _initialized = result ?? false;
    return _initialized;
  }

  static Future<bool> requestPermission() async {
    if (kIsWeb || !_initialized) return false;

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

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

    await _plugin.show(id, title, body, details, payload: payload);
  }

  static void setNotificationTapHandler(
    void Function(String? payload) onTap,
  ) {
    if (kIsWeb || !_initialized) return;

    _plugin.getNotificationAppLaunchDetails().then((details) {
      if (details?.didNotificationLaunchApp == true) {
        onTap(details!.notificationResponse?.payload);
      }
    });

    _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        onTap(response.payload);
      },
    );
  }
}
