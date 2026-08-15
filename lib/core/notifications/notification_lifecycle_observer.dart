import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../features/notifications/services/notification_service.dart';
import '../../features/settings/models/notification_preference.dart';

class NotificationLifecycleObserver extends StatefulWidget {
  final Widget child;
  final NotificationService notificationService;
  final Future<String> Function() getToken;

  /// Liefert die aktuell gewählte Benachrichtigungs-Methode; nur bei
  /// [NotificationMethod.polling] wird bei Resume neu gepollt.
  final NotificationMethod Function() getNotificationMethod;

  const NotificationLifecycleObserver({
    super.key,
    required this.child,
    required this.notificationService,
    required this.getToken,
    required this.getNotificationMethod,
  });

  @override
  State<NotificationLifecycleObserver> createState() =>
      _NotificationLifecycleObserverState();
}

class _NotificationLifecycleObserverState
    extends State<NotificationLifecycleObserver>
    with WidgetsBindingObserver {
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // Nur auf Resume reagieren, wenn die App tatsächlich pausiert war —
        // verhindert mehrfaches startPolling beim Tap auf eine Notification.
        if (_wasPaused) {
          _wasPaused = false;
          _refreshUnread();
          if (widget.getNotificationMethod() == NotificationMethod.polling) {
            _startPolling();
          }
        }
        break;
      case AppLifecycleState.paused:
        if (!_wasPaused) {
          _wasPaused = true;
          widget.notificationService.stopPolling();
        }
        break;
      default:
        break;
    }
  }

  Future<void> _startPolling() async {
    try {
      final token = await widget.getToken();
      widget.notificationService.startPolling(token: token);
    } catch (e) {
      // Token unavailable, polling won't start
    }
  }

  /// Synchronisiert die Unread-Registry mit dem Server bei App-Resume, damit
  /// auf anderen Geräten Gelesenes auch hier den Punkt verschwinden lässt.
  Future<void> _refreshUnread() async {
    try {
      final token = await widget.getToken();
      await widget.notificationService.refreshUnread(token: token);
    } catch (e) {
      // Token unavailable; refresh skipped.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
