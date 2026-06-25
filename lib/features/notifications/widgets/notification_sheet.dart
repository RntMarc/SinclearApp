import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    final notif = AppScope.of(context).notification;
    notif.addListener(_onNotificationsChanged);
    notif.refresh();
  }

  @override
  void dispose() {
    AppScope.of(context).notification.removeListener(_onNotificationsChanged);
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
            const Divider(height: 1),
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
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withAlpha(80),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _header(BuildContext context, NotificationService notif) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Text(
            'Benachrichtigungen',
            style: theme.textTheme.titleLarge,
          ),
          const Spacer(),
          if (notif.unreadCount > 0)
            TextButton.icon(
              onPressed: () async {
                await notif.markAllAsRead();
              },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Alle gelesen'),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Benachrichtigungen',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
    return RefreshIndicator(
      onRefresh: () => AppScope.of(context).notification.refresh(),
      child: ListView.builder(
        controller: scrollController,
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _NotificationItem(
            notification: notification,
            onTap: () => _onNotificationTap(context, notification),
            onDismiss: () async {
              await AppScope.of(context)
                  .notification
                  .markAsRead(notification.id);
            },
          );
        },
      ),
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

    switch (notification.type) {
      case 'recipe_review':
      case 'new_friend_request':
        break;
      default:
        break;
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
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.done_rounded,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            NotificationTypeLabel.icon(notification.type),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          NotificationTypeLabel.title(notification.type),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          NotificationTypeLabel.body(notification.type),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          _timeAgo(notification.createdAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onTap,
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
