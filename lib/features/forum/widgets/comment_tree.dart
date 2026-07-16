import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
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
    final tokens = DesignTheme.of(context);
    final userName = resolveUserName(comment.userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DesignAvatar(
                    imageUrl: comment.userImage,
                    name: userName,
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  DesignText(
                    userName,
                    style: DesignTextStyle.label,
                    color: tokens.textHigh,
                  ),
                  SizedBox(width: tokens.spaceSm),
                  DesignText(
                    app_date.formatRelativeDate(comment.createdAt),
                    style: DesignTextStyle.label,
                    color: tokens.textLow.withValues(alpha: 0.6),
                  ),
                  const Spacer(),
                  if (isOwner || isAdmin)
                    DesignIconButton(
                      icon: Icons.more_vert_rounded,
                      onPressed: () {
                        showDesignSheet<bool>(
                          context: context,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DesignText(
                                'Kommentar löschen',
                                style: DesignTextStyle.subtitle,
                                color: tokens.textHigh,
                              ),
                              SizedBox(height: tokens.spaceMd),
                              DesignText(
                                'Kommentar wirklich löschen?',
                                style: DesignTextStyle.body,
                                color: tokens.textHigh,
                              ),
                              SizedBox(height: tokens.spaceXl),
                              DesignButton(
                                variant: DesignButtonVariant.filled,
                                label: 'Löschen',
                                fullWidth: true,
                                onPressed: () => Navigator.pop(context, true),
                              ),
                              SizedBox(height: tokens.spaceSm),
                              DesignButton(
                                variant: DesignButtonVariant.outlined,
                                label: 'Abbrechen',
                                fullWidth: true,
                                onPressed: () => Navigator.pop(context, false),
                              ),
                            ],
                          ),
                        ).then((confirmed) {
                          if (confirmed == true) onDelete(comment.id);
                        });
                      },
                    ),
                ],
              ),
              SizedBox(height: tokens.spaceXs),
              if (comment.isDeleted)
                DesignText(
                  'Kommentar gelöscht',
                  style: DesignTextStyle.body,
                  color: tokens.textLow.withValues(alpha: 0.5),
                )
              else ...[
                DesignText(
                  comment.text!,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                ),
                SizedBox(height: tokens.spaceXs),
                GestureDetector(
                  onTap: () => onReply(comment.id),
                  child: DesignText(
                    'Antworten',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (comment.children.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: tokens.spaceXl),
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
    final tokens = DesignTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg, vertical: tokens.spaceXs),
      child: Row(
        children: [
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                style: TextStyle(
                  color: tokens.textHigh,
                  fontSize: 15,
                  fontFamily: tokens.fontFamily,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: tokens.textLow,
                    fontSize: 15,
                    fontFamily: tokens.fontFamily,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          if (widget.onCancel != null)
            DesignIconButton(
              icon: Icons.close_rounded,
              onPressed: () {
                _controller.clear();
                widget.onCancel?.call();
              },
            ),
          DesignIconButton(
            icon: Icons.send_rounded,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
