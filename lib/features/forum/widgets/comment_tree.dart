import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../core/widgets/user_avatar.dart';
import '../models/forum_models.dart';

class CommentTreeTile extends StatelessWidget {
  final FeedPostComment comment;
  final String currentUserId;
  final bool isAdmin;
  final String Function(String userId) resolveUserName;
  final ValueChanged<String> onReply;
  final ValueChanged<String> onDelete;

  const CommentTreeTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.isAdmin,
    required this.resolveUserName,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = comment.userId == currentUserId;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    imageUrl: comment.userImage,
                    displayName: resolveUserName(comment.userId),
                    radius: 10,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    resolveUserName(comment.userId),
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
                  if (isOwner || isAdmin)
                    PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        if (isOwner)
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
                                Text(
                                  'Löschen',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') onDelete(comment.id);
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
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                )
              else ...[
                Text(
                  comment.text!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => onReply(comment.id),
                  child: Text(
                    'Antworten',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (comment.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: comment.children
                  .map(
                    (child) => CommentTreeTile(
                      comment: child,
                      currentUserId: currentUserId,
                      isAdmin: isAdmin,
                      resolveUserName: resolveUserName,
                      onReply: onReply,
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

class CommentInput extends StatefulWidget {
  final String hintText;
  final bool autofocus;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onCancel;

  const CommentInput({
    super.key,
    this.hintText = 'Kommentar schreiben...',
    this.autofocus = false,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      widget.onSubmit(text);
      _controller.clear();
      _focusNode.unfocus();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (widget.onCancel != null)
            IconButton(
              onPressed: () {
                _controller.clear();
                widget.onCancel?.call();
              },
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          IconButton(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
          ),
        ],
      ),
    );
  }
}
