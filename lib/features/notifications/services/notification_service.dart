// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/services/auth_service.dart';
import '../models/notification_models.dart';
import 'notification_display.dart';

class NotificationService extends ChangeNotifier {
  final ApiClient _api;
  final AuthService _auth;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  String? _fcmToken;
  String? _deviceId;
  Timer? _pollTimer;
  bool _initialized = false;
  String? _pendingNotificationId;
  void Function(String notificationId)? onNotificationTapped;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _initialized;
  String? consumePendingNotificationId() {
    final id = _pendingNotificationId;
    _pendingNotificationId = null;
    return id;
  }

  NotificationService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (!kIsWeb) {
      await localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              description: channelDescription,
              importance: Importance.high,
            ),
          );

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );
    }

    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows);

    if (!isDesktop) {
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
      }

      final messaging = FirebaseMessaging.instance;

      if (kIsWeb) {
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        developer.log(
          'Web notification permission: ${settings.authorizationStatus}',
          name: 'notifications',
        );
      } else {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidPlugin = localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          await androidPlugin?.requestNotificationsPermission();
        }
      }

      _fcmToken = await messaging.getToken();
      developer.log('FCM token: $_fcmToken', name: 'notifications');
      if (_fcmToken != null && _auth.isLoggedIn) {
        await _registerDevice();
      }

      messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        developer.log('FCM token refreshed: $token', name: 'notifications');
        if (_auth.isLoggedIn) _registerDevice();
      });

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        developer.log(
          'Notification opened app: ${message.messageId}',
          name: 'notifications',
        );
        final notificationId = message.data['notificationId'] as String?;
        if (notificationId != null) {
          onNotificationTapped?.call(notificationId);
        }
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        developer.log(
          'Initial message: ${initialMessage.messageId}',
          name: 'notifications',
        );
        final notificationId = initialMessage.data['notificationId'] as String?;
        if (notificationId != null) {
          _pendingNotificationId = notificationId;
        }
      }
    }

    _setupPolling();
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    developer.log('Local notification tapped: $payload', name: 'notifications');

    if (payload.startsWith('fallback|')) {
      final notificationId = payload.substring('fallback|'.length);
      onNotificationTapped?.call(notificationId);
    }
  }

  void onLoggedIn() {
    if (_fcmToken != null) _registerDevice();
    _fetchNotifications();
    _startPolling();
  }

  Future<void> onLoggedOut() async {
    _stopPolling();
    if (_deviceId != null) {
      try {
        await _api.delete(
          '/notifications/devices/$_deviceId',
          token: await _token(),
        );
      } catch (_) {}
      _deviceId = null;
    }
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> _registerDevice() async {
    if (_fcmToken == null) return;
    String platform;
    if (kIsWeb) {
      platform = 'web';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          platform = 'android';
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          platform = 'ios';
        case TargetPlatform.windows:
          platform = 'windows';
        case TargetPlatform.linux:
          platform = 'linux';
        case TargetPlatform.fuchsia:
          platform = 'android';
      }
    }

    try {
      final data = await _api.post(
        '/notifications/devices',
        body: DeviceRegisterRequest(
          token: _fcmToken!,
          platform: platform,
        ).toJson(),
        token: await _token(),
      );
      _deviceId = data['data']['id'] as String;
      developer.log('Device registered: $_deviceId', name: 'notifications');
    } catch (e, s) {
      developer.log(
        'Device registration failed: $e',
        name: 'notifications',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    developer.log(
      'Foreground message: ${message.messageId}',
      name: 'notifications',
    );

    final notificationId = message.data['notificationId'] as String?;
    if (notificationId == null) return;

    final existingIds = _notifications.map((n) => n.id).toSet();
    if (existingIds.contains(notificationId)) return;

    try {
      final data = await _api.get(
        '/notifications/$notificationId',
        token: await _token(),
      );
      final notification = AppNotification.fromJson(
        data['data'] as Map<String, dynamic>,
      );
      _notifications.insert(0, notification);
      _unreadCount++;
      notifyListeners();

      await showLocalNotification(notification);
    } catch (e, s) {
      developer.log(
        'Failed to fetch foreground notification: $e',
        name: 'notifications',
        error: e,
        stackTrace: s,
      );
    }
  }

  // --- API Calls ---

  Future<NotificationListResponse> getNotifications({
    String? since,
    int limit = 50,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (since != null) params['since'] = since;

    final data = await _api.get(
      '/notifications',
      queryParams: params,
      token: await _token(),
    );
    return NotificationListResponse.fromJson(data);
  }

  Future<AppNotification> getNotification(String id) async {
    final data = await _api.get('/notifications/$id', token: await _token());
    return AppNotification.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteNotification(String id) async {
    await _api.delete('/notifications/$id', token: await _token());
  }

  Future<int> deleteAllNotifications() async {
    final data = await _api.delete('/notifications', token: await _token());
    return data['data']['deleted'] as int;
  }

  Future<List<Device>> getDevices() async {
    final data = await _api.get(
      '/notifications/devices',
      token: await _token(),
    );
    final list = data['data'] as List;
    return list.map((e) => Device.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteDevice(String deviceId) async {
    await _api.delete(
      '/notifications/devices/$deviceId',
      token: await _token(),
    );
  }

  // --- Fetch & Refresh ---

  Future<void> _fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final since = prefs.getString('last_polled_at');
      final response = await getNotifications(since: since, limit: 50);
      final existingIds = _notifications.map((n) => n.id).toSet();
      for (final n in response.data) {
        if (!existingIds.contains(n.id)) {
          _notifications.insert(0, n);
        }
      }
      _unreadCount = response.meta.unreadCount;
      await prefs.setString(
        'last_polled_at',
        toApiDate(DateTime.now()),
      );
      notifyListeners();
    } catch (e, s) {
      developer.log(
        'Fetch notifications failed: $e',
        name: 'notifications',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> refresh() async {
    await _fetchNotifications();
  }

  Future<void> markAsRead(String id) async {
    await deleteNotification(id);
    final before = _notifications.length;
    _notifications.removeWhere((n) => n.id == id);
    if (_notifications.length < before && _unreadCount > 0) _unreadCount--;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await deleteAllNotifications();
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  // --- Polling (Linux / Windows) ---

  void _setupPolling() {
    if (!_auth.isLoggedIn) return;
    _startPolling();
  }

  void _startPolling() {
    final isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows);
    if (!isDesktop) return;

    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final since = prefs.getString('last_polled_at');
        final response = await getNotifications(since: since, limit: 50);
        if (response.data.isNotEmpty) {
          final existingIds = _notifications.map((n) => n.id).toSet();
          for (final notification in response.data) {
            if (!existingIds.contains(notification.id)) {
              _notifications.insert(0, notification);
              await showLocalNotification(notification);
            }
          }
          _unreadCount = response.meta.unreadCount;
          notifyListeners();
        }
        await prefs.setString(
          'last_polled_at',
          toApiDate(DateTime.now()),
        );
      } catch (e, s) {
        developer.log(
          'Polling failed: $e',
          name: 'notifications.polling',
          error: e,
          stackTrace: s,
        );
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
