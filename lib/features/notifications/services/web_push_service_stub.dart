
class WebPushPlatformHelper {
  static bool get isSupported => false;

  static Future<String?> requestPermission() async => null;

  static Future<Map<String, dynamic>?> subscribe(String vapidKey) async => null;

  static Future<String?> getEndpoint() async => null;

  static Future<bool> unsubscribe() async => false;
}
