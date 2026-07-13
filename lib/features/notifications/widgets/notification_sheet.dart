import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/notification_models.dart';
import '../services/notification_service.dart';
import '../../../core/config/notification_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/composite/design_list_tile.dart';

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
    final tokens = DesignTheme.of(context);
    final notif = AppScope.of(context).notification;
    final notifications = notif.notifications;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(tokens.radiusXl),
            ),
            boxShadow: tokens.surfaceShadow,
          ),
          child: Column(
            children: [
              _handle(tokens),
              _header(tokens, notif),
              const DesignDivider(),
              Expanded(
                child: notifications.isEmpty
                    ? _emptyState(tokens)
                    : _list(context, notifications, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _handle(DesignTokens tokens) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: tokens.textLow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _header(DesignTokens tokens, NotificationService notif) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          DesignText(
            'Benachrichtigungen',
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          const Spacer(),
          if (notif.unreadCount > 0)
            DesignButton(
              variant: DesignButtonVariant.text,
              icon: Icons.done_all_rounded,
              label: 'Alle gelesen',
              onPressed: () async {
                await notif.markAllAsRead();
              },
            ),
        ],
      ),
    );
  }

  Widget _emptyState(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: tokens.textLow.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          DesignText(
            'Keine Benachrichtigungen',
            style: DesignTextStyle.body,
            color: tokens.textLow,
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
              await AppScope.of(
                context,
              ).notification.markAsRead(notification.id);
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

    if (notification.code == 'location_sharing.started') {
      context.go('/standort-teilen');
      return;
    }

    final deepLink = notification.payload['deepLink'] as String?;
    if (deepLink != null) {
      context.go(deepLink);
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
    final tokens = DesignTheme.of(context);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: tokens.surfaceVariant,
        child: Icon(
          Icons.done_rounded,
          color: tokens.primary,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DesignListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              NotificationTypeLabel.icon(notification.code, notification.payload),
              color: tokens.primary,
              size: 20,
            ),
          ),
          title: NotificationTypeLabel.title(notification.code, notification.payload),
          subtitle: NotificationTypeLabel.body(notification.code, notification.payload),
          trailing: DesignText(
            _timeAgo(notification.createdAt),
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _timeAgo(String isoDate) {
    try {
      final date = parseApiDate(isoDate);
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
