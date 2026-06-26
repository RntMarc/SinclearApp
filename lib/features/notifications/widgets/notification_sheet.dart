import 'package:flutter/cupertino.dart';
import '../models/notification_models.dart';
import '../services/notification_service.dart';
import '../../../core/config/notification_config.dart';
import '../../../core/di/app_scope.dart';

class NotificationSheet extends StatefulWidget {
  const NotificationSheet({super.key});

  @override
  State<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<NotificationSheet> {
  NotificationService? _notification;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notification ??= AppScope.of(context).notification;
    _notification!.addListener(_onNotificationsChanged);
    _notification!.refresh();
  }

  @override
  void dispose() {
    _notification?.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notif = AppScope.of(context).notification;
    final notifications = notif.notifications;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            _handle(context),
            _header(context, notif),
            Container(height: 1, color: CupertinoColors.systemGrey4),
            Expanded(
              child: notifications.isEmpty
                  ? _emptyState(context)
                  : _list(context, notifications, scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _handle(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey3,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _header(BuildContext context, NotificationService notif) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          const Text(
            'Benachrichtigungen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (notif.unreadCount > 0)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                await notif.markAllAsRead();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.checkmark_seal_fill, size: 16),
                  SizedBox(width: 4),
                  Text('Alle gelesen'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.bell_slash,
            size: 64,
            color: CupertinoColors.systemGrey2,
          ),
          SizedBox(height: 16),
          Text(
            'Keine Benachrichtigungen',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<AppNotification> notifications,
    ScrollController scrollController,
  ) {
    return ListView.builder(
      controller: scrollController,
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationItem(
          notification: notification,
          onTap: () => _onNotificationTap(context, notification),
          onDismiss: () async {
            await AppScope.of(
              context,
            ).notification.markAsRead(notification.id);
          },
        );
      },
    );
  }

  void _onNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) async {
    final notifService = AppScope.of(context).notification;
    await notifService.markAsRead(notification.id);
    if (!context.mounted) return;

    Navigator.pop(context);

    final deepLink = notification.payload['deepLink'] as String?;
    if (deepLink != null) {
      // Navigate to deepLink via router
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: theme.primaryColor.withValues(alpha: 0.15),
        child: Icon(
          CupertinoIcons.checkmark_alt,
          color: theme.primaryColor,
        ),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: CupertinoColors.systemGrey5,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    NotificationTypeLabel.icon(
                      notification.code,
                      notification.payload,
                    ),
                    color: theme.primaryColor,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      NotificationTypeLabel.title(
                        notification.code,
                        notification.payload,
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.textStyle.color,
                      ),
                    ),
                    Text(
                      NotificationTypeLabel.body(
                        notification.code,
                        notification.payload,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _timeAgo(notification.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Jetzt';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${diff.inDays ~/ 7}w';
    } catch (_) {
      return '';
    }
  }
}
