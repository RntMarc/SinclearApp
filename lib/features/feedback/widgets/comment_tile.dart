import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../models/feedback_models.dart';

class CommentTile extends StatelessWidget {
  final FeedbackComment comment;
  final String currentUserId;
  final bool isAdmin;
  final String Function(String userId) resolveUserName;
  final ValueChanged<String> onReply;
  final ValueChanged<String> onEdit;
  final ValueChanged<String> onDelete;

  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.isAdmin,
    required this.resolveUserName,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = comment.userId == currentUserId;
    final canEdit =
        isOwner &&
        !comment.isDeleted &&
        DateTime.now().difference(app_date.parseApiDate(comment.createdAt)).inMinutes <
            10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentBody(
          comment: comment,
          userName: resolveUserName(comment.userId),
          isOwner: isOwner,
          isAdmin: isAdmin,
          canEdit: canEdit,
          onReply: () => onReply(comment.id),
          onEdit: canEdit ? () => onEdit(comment.id) : null,
          onDelete: (isOwner || isAdmin) ? () => onDelete(comment.id) : null,
        ),
        if (comment.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: comment.children
                  .map(
                    (child) => CommentTile(
                      comment: child,
                      currentUserId: currentUserId,
                      isAdmin: isAdmin,
                      resolveUserName: resolveUserName,
                      onReply: onReply,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _CommentBody extends StatelessWidget {
  final FeedbackComment comment;
  final String userName;
  final bool isOwner;
  final bool isAdmin;
  final bool canEdit;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CommentBody({
    required this.comment,
    required this.userName,
    required this.isOwner,
    required this.isAdmin,
    required this.canEdit,
    required this.onReply,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_rounded,
                size: 20,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Text(
                userName,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                app_date.formatRelativeDate(comment.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              if (onDelete != null || onEdit != null)
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Bearbeiten'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Löschen', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (comment.isDeleted)
            Text(
              'Kommentar gelöscht',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            )
          else
            Text(
              comment.text!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onReply,
            child: Text(
              'Antworten',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
