// ignore_for_file: prefer_initializing_formals, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/notifications/local_notification_helper.dart';
import '../../../firebase_options.dart';
import 'background_poller.dart';

/// Top-Level Background-Handler für Google FCM (nur Android).
///
/// STRIKTE DATENSCHUTZREGEL:
/// Die FCM-Nachricht selbst enthält keinerlei persönliche Inhalte (nur
/// `wakeup: "1"` und `notificationId`). Dieser Handler weckt die App im
/// Hintergrund auf und ruft den eigentlichen Inhalt direkt und authentifiziert
/// über [pollNotificationsHeadless] von der Sinclear-API ab.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) return;

  final ok = await pollNotificationsHeadless(force: true);
  if (!ok) {
    final notificationId = message.data['notificationId'] as String?;
    if (notificationId != null && notificationId.isNotEmpty) {
      await LocalNotificationHelper.init();
      await LocalNotificationHelper.show(
        id: stableNotificationId(notificationId),
        title: 'Neue Mitteilung',
        body: 'Öffne Beyond, um deine neuen Benachrichtigungen zu lesen.',
        payload: jsonEncode({'id': notificationId, 'type': 'unknown'}),
      );
    }
  }
}

/// Verwaltet die Google-FCM-Integration (ausschließlich natives Android).
///
/// Web/PWA verwendet niemals FCM, sondern immer Browser-Web-Push (`web/sw.js`).
class FcmPushService extends ChangeNotifier {
  static const _savedTokenKey = 'fcm_saved_token';

  final ApiClient _api;
  Future<String> Function()? _getToken;
  Future<void> Function()? _onWakeup;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  String? _fcmToken;
  bool _firebaseInitialized = false;

  FcmPushService({required ApiClient api}) : _api = api;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// Initialisiert Firebase (nur Android), holt das FCM-Token, registriert es
  /// als `type: 'fcm'` bei der API und lauscht auf Wakeup-Pushes.
  Future<bool> setup({
    required Future<String> Function() getToken,
    required Future<void> Function() onWakeup,
  }) async {
    if (!_isAndroid) return false;
    _getToken = getToken;
    _onWakeup = onWakeup;

    try {
      await _ensureFirebaseInitialized();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }

      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        return false;
      }
      _fcmToken = fcmToken;
      await _registerToken(fcmToken);

      _tokenRefreshSub ??= messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        unawaited(_registerToken(newToken));
      });

      _foregroundMessageSub ??= FirebaseMessaging.onMessage.listen((_) {
        final callback = _onWakeup;
        if (callback != null) {
          unawaited(callback());
        }
      });

      return true;
    } catch (e, st) {
      developer.log(
        'FCM setup failed',
        error: e,
        stackTrace: st,
        name: 'fcm_push',
      );
      return false;
    }
  }

  /// Meldet das Gerät von FCM-Wakeup-Pushes ab (Methodenwechsel oder Logout).
  Future<void> unregister({String? token}) async {
    if (!_isAndroid) return;

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _foregroundMessageSub?.cancel();
    _foregroundMessageSub = null;

    var endpoint = _fcmToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      endpoint ??= prefs.getString(_savedTokenKey);
      await prefs.remove(_savedTokenKey);
    } catch (_) {}

    if (endpoint != null && endpoint.isNotEmpty) {
      try {
        final accessToken = token ?? await _getToken?.call();
        if (accessToken != null && accessToken.isNotEmpty) {
          await _api.delete(
            '/notifications/push-subscription',
            body: {'endpoint': endpoint},
            token: accessToken,
          );
        }
      } catch (e) {
        developer.log('Failed to unregister FCM token: $e', name: 'fcm_push');
      }
    }

    try {
      if (_firebaseInitialized) {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) {}
    _fcmToken = null;
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (_firebaseInitialized) return;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _firebaseInitialized = true;
  }

  Future<void> _registerToken(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedTokenKey, endpoint);
    } catch (_) {}

    final getToken = _getToken;
    if (getToken == null) return;

    try {
      final accessToken = await getToken();
      await _api.post(
        '/notifications/push-subscription',
        body: {'type': 'fcm', 'endpoint': endpoint},
        token: accessToken,
      );
    } catch (e) {
      developer.log('Failed to register FCM token: $e', name: 'fcm_push');
    }
  }
}
