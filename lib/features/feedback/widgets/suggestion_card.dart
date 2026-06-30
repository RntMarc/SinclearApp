import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../models/feedback_models.dart';

class SuggestionCard extends StatelessWidget {
  final FeedbackSuggestion suggestion;
  final bool isOwner;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onVote;
  final VoidCallback onDelete;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.isOwner,
    required this.isAdmin,
    required this.onTap,
    required this.onVote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(suggestion.status, theme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      suggestion.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatusBadge(label: suggestion.status.label, color: statusColor),
                ],
              ),
              if (suggestion.description != null &&
                  suggestion.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  suggestion.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _VoteButton(
                    count: suggestion.upvoteCount,
                    hasVoted: suggestion.hasVoted,
                    onTap: onVote,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    app_date.formatRelativeDate(suggestion.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isOwner || isAdmin)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      itemBuilder: (context) => [
                        if (isOwner || isAdmin)
                          const PopupMenuItem(
                            value: 'delete',
                            child: _MenuAction(
                              icon: Icons.delete_outline_rounded,
                              label: 'Löschen',
                              color: Colors.red,
                            ),
                          ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') onDelete();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(FeedbackStatus status, ThemeData theme) {
    switch (status) {
      case FeedbackStatus.submitted:
        return theme.colorScheme.onSurfaceVariant;
      case FeedbackStatus.planned:
        return Colors.blue;
      case FeedbackStatus.next:
        return Colors.orange;
      case FeedbackStatus.inProgress:
        return Colors.amber.shade700;
      case FeedbackStatus.done:
        return Colors.green;
      case FeedbackStatus.cancelled:
        return theme.colorScheme.error;
      case FeedbackStatus.rejected:
        return theme.colorScheme.error;
      case FeedbackStatus.later:
        return Colors.purple;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final int count;
  final bool hasVoted;
  final VoidCallback onTap;

  const _VoteButton({
    required this.count,
    required this.hasVoted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hasVoted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasVoted
                  ? Icons.thumb_up_rounded
                  : Icons.thumb_up_outlined,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MenuAction({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
