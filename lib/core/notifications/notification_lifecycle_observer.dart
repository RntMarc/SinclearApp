import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../features/notifications/services/notification_service.dart';

class NotificationLifecycleObserver extends StatefulWidget {
  final Widget child;
  final NotificationService notificationService;
  final Future<String> Function() getToken;

  const NotificationLifecycleObserver({
    super.key,
    required this.child,
    required this.notificationService,
    required this.getToken,
  });

  @override
  State<NotificationLifecycleObserver> createState() =>
      _NotificationLifecycleObserverState();
}

class _NotificationLifecycleObserverState
    extends State<NotificationLifecycleObserver> with WidgetsBindingObserver {
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
        _startPolling();
        break;
      case AppLifecycleState.paused:
        widget.notificationService.stopPolling();
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

  @override
  Widget build(BuildContext context) => widget.child;
}
