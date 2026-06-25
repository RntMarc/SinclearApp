import 'package:web/web.dart' as web;

void showWebNotification(String title, String body) {
  if (web.Notification.permission == 'granted') {
    web.Notification(
      title,
      web.NotificationOptions(
        body: body,
        icon: '/icons/icon-192x192.png',
      ),
    );
  }
}
