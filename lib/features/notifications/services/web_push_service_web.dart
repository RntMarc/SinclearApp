import 'dart:convert';
import 'package:web/web.dart' as web;

class WebPushPlatformHelper {
  static bool get isSupported =>
      web.window.Notification.supported;

  static Future<String?> requestPermission() async {
    final permission = await web.window.Notification.requestPermission();
    return permission == 'granted' ? permission : null;
  }

  static Future<Map<String, dynamic>?> subscribe(String vapidKey) async {
    final registration = await web.window.navigator.serviceWorker.ready;

    final subscription = await registration.pushManager.subscribe(
      web.PushSubscriptionOptions(
        userVisibleOnly: true,
        applicationServerKey: web.Uint8List.fromList(
          _base64UrlDecode(vapidKey),
        ),
      ),
    );

    final endpoint = subscription.endpoint;
    final p256dh = subscription.getKey('p256dh');
    final auth = subscription.getKey('auth');

    if (p256dh == null || auth == null) return null;

    return {
      'endpoint': endpoint,
      'p256dh': base64Url.encode(p256dh),
      'auth': base64Url.encode(auth),
    };
  }

  static Future<String?> getEndpoint() async {
    final registration = await web.window.navigator.serviceWorker.ready;
    final subscription = await registration.pushManager.getSubscription();
    return subscription?.endpoint;
  }

  static Future<bool> unsubscribe() async {
    final registration = await web.window.navigator.serviceWorker.ready;
    final subscription = await registration.pushManager.getSubscription();
    if (subscription != null) {
      return await subscription.unsubscribe();
    }
    return false;
  }

  static List<int> _base64UrlDecode(String input) {
    var output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Invalid base64url string');
    }
    return base64.decode(output);
  }
}
