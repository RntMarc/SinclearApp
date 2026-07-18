// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_models.dart';
import '../../../core/config/notification_config.dart';
import 'notification_helper_stub.dart'
    if (dart.library.html) 'notification_helper_web.dart';

const channelId = 'sinclear_notifications';
const channelName = 'Sinclear Benachrichtigungen';
const channelDescription = 'Benachrichtigungen über Aktivitäten in Sinclear';

final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> showFallbackNotification(String notificationId) async {
  if (kIsWeb) {
    showWebNotification('Sinclear', 'Du hast eine neue Benachrichtigung.');
    return;
  }
  final androidDetails = const AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDescription,
    importance: Importance.high,
    priority: Priority.high,
  );
  final details = NotificationDetails(
    android: androidDetails,
    iOS: const DarwinNotificationDetails(),
  );
  await localNotifications.show(
    id: notificationId.hashCode,
    title: 'Sinclear',
    body: 'Du hast eine neue Benachrichtigung.',
    notificationDetails: details,
    payload: 'fallback|$notificationId',
  );
}

Future<void> showLocalNotification(AppNotification notification) async {
  final title = NotificationTypeLabel.title(
    notification.code,
    notification.payload,
  );
  final body = NotificationTypeLabel.body(
    notification.code,
    notification.payload,
  );

  if (kIsWeb) {
    showWebNotification(title, body);
    return;
  }

  final androidDetails = const AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDescription,
    importance: Importance.high,
    priority: Priority.high,
  );

  final details = NotificationDetails(
    android: androidDetails,
    iOS: const DarwinNotificationDetails(),
  );

  await localNotifications.show(
    id: notification.id.hashCode,
    title: title,
    body: body,
    notificationDetails: details,
    payload: '${notification.code}|${jsonEncode(notification.payload)}',
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    'BG handler received: ${message.messageId}',
    name: 'notifications.bg',
  );

  final notificationId = message.data['notificationId'] as String?;
  if (notificationId == null) return;

  await showFallbackNotification(notificationId);

  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString('refresh_token');
  if (refreshToken == null) {
    developer.log('BG handler: no refresh token', name: 'notifications.bg');
    return;
  }

  final baseUrl =
      prefs.getString('api_base_url') ?? 'http://localhost:8000/api/v2';

  try {
    final refreshBody = {'refresh_token': refreshToken};
    final refreshResp = await http
        .post(
          Uri.parse('$baseUrl/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(refreshBody),
        )
        .timeout(const Duration(seconds: 10));
    if (refreshResp.statusCode != 200) {
      developer.log(
        'BG handler: refresh failed ${refreshResp.statusCode}',
        name: 'notifications.bg',
      );
      return;
    }
    final refreshData = jsonDecode(refreshResp.body) as Map<String, dynamic>;
    final accessToken = refreshData['access_token'] as String;

    final newRefreshToken = refreshData['refresh_token'] as String?;
    if (newRefreshToken != null) {
      await prefs.setString('refresh_token', newRefreshToken);
    }

    final notifResp = await http
        .get(
          Uri.parse('$baseUrl/notifications/$notificationId'),
          headers: {'Authorization': 'Bearer $accessToken'},
        )
        .timeout(const Duration(seconds: 10));

    if (notifResp.statusCode != 200) {
      developer.log(
        'BG handler: fetch failed ${notifResp.statusCode}',
        name: 'notifications.bg',
      );
      return;
    }

    final notifData = jsonDecode(notifResp.body) as Map<String, dynamic>;
    final notification = AppNotification.fromJson(
      notifData['data'] as Map<String, dynamic>,
    );

    await showLocalNotification(notification);
  } catch (e, s) {
    developer.log(
      'BG handler error: $e',
      name: 'notifications.bg',
      error: e,
      stackTrace: s,
    );
  }
}
