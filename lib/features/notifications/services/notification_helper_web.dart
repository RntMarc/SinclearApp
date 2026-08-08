import 'package:web/web.dart' as web;

void showWebNotification(String title, String body) {
  if (web.Notification.permission == 'granted') {
    web.Notification(
      title,
      web.NotificationOptions(body: body, icon: '/icons/icon-192x192.png'),
    );
  }
}

/// Returns the notification id from the URL the web app was launched with
/// (?notification=…, set by the service worker on notification click) and
/// removes the query parameter so later launches do not re-trigger.
String? takeNotificationIdFromUrl() {
  final uri = Uri.parse(web.window.location.href);
  final id = uri.queryParameters['notification'];
  if (id == null || id.isEmpty) return null;
  final clean = uri.replace(
    queryParameters: {...uri.queryParameters}..remove('notification'),
  );
  web.window.history.replaceState(null, '', clean.toString());
  return id;
}
