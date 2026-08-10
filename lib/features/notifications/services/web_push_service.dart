import 'dart:developer' as developer;
import '../../../core/network/api_client.dart';
import 'web_push_service_stub.dart'
    if (dart.library.js_interop) 'web_push_service_web.dart';

class WebPushService {
  final ApiClient _api;

  WebPushService({required this._api});

  bool get isSupported => WebPushPlatformHelper.isSupported;

  Future<void> setup({required String token}) async {
    if (!isSupported) return;

    try {
      final permission = await WebPushPlatformHelper.requestPermission();
      if (permission == null) return;

      final vapidResponse = await _api.get('/notifications/vapid-public-key');
      final vapidKey = vapidResponse['key'] as String;

      final keys = await WebPushPlatformHelper.subscribe(vapidKey);
      if (keys == null) return;

      await _api.post(
        '/notifications/push-subscription',
        body: {
          'type': 'webpush',
          'endpoint': keys['endpoint'],
          'keys': {
            'p256dh': keys['p256dh'],
            'auth': keys['auth'],
          },
        },
        token: token,
      );
    } catch (e) {
      developer.log('Web Push setup failed: $e', name: 'web_push');
    }
  }

  Future<void> unsubscribe({required String token}) async {
    if (!isSupported) return;

    try {
      final endpoint = await WebPushPlatformHelper.getEndpoint();
      if (endpoint != null) {
        await WebPushPlatformHelper.unsubscribe();

        await _api.delete(
          '/notifications/push-subscription',
          body: {'endpoint': endpoint},
          token: token,
        );
      }
    } catch (e) {
      developer.log('Web Push unsubscribe failed: $e', name: 'web_push');
    }
  }
}
