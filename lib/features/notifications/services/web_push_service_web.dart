import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

class WebPushPlatformHelper {
  static bool get isSupported {
    try {
      return web.Notification.permission.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> requestPermission() async {
    final permission =
        (await web.Notification.requestPermission().toDart).toDart;
    return permission == 'granted' ? permission : null;
  }

  static Future<Map<String, dynamic>?> subscribe(String vapidKey) async {
    final registration = await web.window.navigator.serviceWorker.ready.toDart;

    final subscription = await registration.pushManager
        .subscribe(
          web.PushSubscriptionOptionsInit(
            userVisibleOnly: true,
            applicationServerKey: Uint8List.fromList(
              _base64UrlDecode(vapidKey),
            ).buffer.toJS,
          ),
        )
        .toDart;

    final p256dh = subscription.getKey('p256dh')?.toDart.asUint8List();
    final auth = subscription.getKey('auth')?.toDart.asUint8List();

    if (p256dh == null || auth == null) return null;

    return {
      'endpoint': subscription.endpoint,
      'p256dh': base64Url.encode(p256dh),
      'auth': base64Url.encode(auth),
    };
  }

  static Future<String?> getEndpoint() async {
    final registration = await web.window.navigator.serviceWorker.ready.toDart;
    final subscription = await registration.pushManager
        .getSubscription()
        .toDart;
    return subscription?.endpoint;
  }

  static Future<bool> unsubscribe() async {
    final registration = await web.window.navigator.serviceWorker.ready.toDart;
    final subscription = await registration.pushManager
        .getSubscription()
        .toDart;
    if (subscription != null) {
      return (await subscription.unsubscribe().toDart).toDart;
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
