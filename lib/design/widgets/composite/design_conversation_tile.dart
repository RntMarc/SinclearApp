import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_avatar.dart';
import '../primitives/design_badge.dart';
import '../primitives/design_card.dart';
import '../primitives/design_pulse_dot.dart';

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
  final bool isTyping;

  /// 1:1: Ist das Gegenüber gerade im Chat anwesend? Zeigt einen grünen
  /// Punkt auf dem Avatar.
  final bool isOnline;

  /// Gruppe: Anzahl anwesender Nutzer; `null` bei 1:1.
  final int? onlineCount;

  /// Gruppe: Gesamtzahl der Mitglieder; `null` bei 1:1.
  final int? memberCount;
  final VoidCallback? onTap;

  const DesignConversationTile({
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isTyping = false,
    this.isOnline = false,
    this.onlineCount,
    this.memberCount,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final unread = unreadCount > 0;
    final showGroupPresence = onlineCount != null && memberCount != null;
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              DesignAvatar(imageUrl: avatarUrl, name: name, size: 48),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.surface,
                    ),
                    child: DesignPulseDot(
                      size: 10,
                      color: tokens.success,
                      semanticLabel: 'Online',
                    ),
                  ),
                ),
            ],
          ),
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
                  isTyping
                      ? 'schreibt…'
                      : lastMessage ?? 'Noch keine Nachrichten',
                  style: DesignTextStyle.label,
                  color: isTyping
                      ? tokens.accentA
                      : unread
                      ? tokens.textHigh
                      : tokens.textLow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showGroupPresence || lastMessageAt != null || unread) ...[
            SizedBox(width: tokens.spaceMd),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showGroupPresence)
                  _GroupPresence(
                    online: onlineCount!,
                    total: memberCount!,
                    color: _presenceColor(tokens),
                  ),
                if (showGroupPresence && lastMessageAt != null)
                  SizedBox(height: tokens.spaceXs),
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

  Color _presenceColor(DesignTokens tokens) {
    final online = onlineCount!;
    final total = memberCount!;
    if (total > 0 && online >= total) return tokens.success;
    if (online > 0) return tokens.warning;
    return tokens.textLow;
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

/// Gruppe: farbiger Punkt plus `online/gesamt`.
class _GroupPresence extends StatelessWidget {
  final int online;
  final int total;
  final Color color;

  const _GroupPresence({
    required this.online,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Semantics(
      label: '$online von $total online',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            SizedBox(width: tokens.spaceXs),
            DesignText(
              '$online/$total',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
        ),
      ),
    );
  }
}
