import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_avatar.dart';
import '../primitives/design_badge.dart';
import '../primitives/design_card.dart';

/// Listeneintrag einer Chat-Konversation: Avatar, Name, Nachrichten-Vorschau,
/// Zeitstempel und Unread-Badge. Ungelesene Konversationen erhalten den
/// pulsierenden Akzent-Glow über [DesignCard.pulseColor].
class DesignConversationTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String? lastMessage;

  /// Zeit der letzten Nachricht; `null` wenn noch keine Nachricht.
  final DateTime? lastMessageAt;
  final int unreadCount;
  final VoidCallback? onTap;

  const DesignConversationTile({
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final unread = unreadCount > 0;
    return DesignCard(
      margin: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceXs,
      ),
      onTap: onTap,
      pulseColor: unread ? tokens.accentA : null,
      padding: EdgeInsets.all(tokens.spaceMd),
      child: Row(
        children: [
          DesignAvatar(imageUrl: avatarUrl, name: name, size: 48),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  name,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: tokens.spaceXs),
                DesignText(
                  lastMessage ?? 'Noch keine Nachrichten',
                  style: DesignTextStyle.label,
                  color: unread ? tokens.textHigh : tokens.textLow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (lastMessageAt != null || unread) ...[
            SizedBox(width: tokens.spaceMd),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMessageAt != null)
                  DesignText(
                    _timeLabel(lastMessageAt!),
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                  ),
                if (unread) ...[
                  SizedBox(height: tokens.spaceXs),
                  DesignBadge(
                    label: unreadCount > 99 ? '99+' : '$unreadCount',
                    color: tokens.accentA,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _timeLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) return formatTime(date);
    if (day == today.subtract(const Duration(days: 1))) return 'Gestern';
    return formatDate(date);
  }
}
