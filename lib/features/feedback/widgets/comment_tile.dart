import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../models/feedback_models.dart';

/// A single feedback comment with optional replies, edit and delete actions.
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

  void _openMenu(BuildContext context, bool canEdit) {
    final tokens = DesignTheme.of(context);
    showDesignSheet(
      context: context,
      child: Column(
        children: [
          if (canEdit)
            DesignListTile(
              leading: Icon(Icons.edit_outlined, color: tokens.textHigh, size: 20),
              title: 'Bearbeiten',
              onTap: () {
                Navigator.of(context).pop();
                onEdit(comment.id);
              },
            ),
          DesignListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: tokens.danger,
              size: 20,
            ),
            title: 'Löschen',
            onTap: () {
              Navigator.of(context).pop();
              onDelete(comment.id);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final isOwner = comment.userId == currentUserId;
    final canEdit =
        isOwner &&
        !comment.isDeleted &&
        DateTime.now()
                .difference(app_date.parseApiDate(comment.createdAt))
                .inMinutes <
            10;

    final menuAction = (isOwner || isAdmin)
        ? DesignIconButton(
            icon: Icons.more_vert_rounded,
            onPressed: () => _openMenu(context, canEdit),
          )
        : null;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_circle_rounded,
              size: 20,
              color: tokens.primary.withValues(alpha: 0.6),
            ),
            SizedBox(width: tokens.spaceSm),
            DesignText(
              resolveUserName(comment.userId),
              style: DesignTextStyle.label,
              color: tokens.textHigh,
            ),
            SizedBox(width: tokens.spaceMd),
            DesignText(
              app_date.formatRelativeDate(comment.createdAt),
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
            const Spacer(),
            menuAction ?? const SizedBox.shrink(),
          ],
        ),
        SizedBox(height: tokens.spaceXs),
        if (comment.isDeleted)
          DesignText(
            'Kommentar gelöscht',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          )
        else
          DesignText(
            comment.text!,
            style: DesignTextStyle.body,
          ),
        SizedBox(height: tokens.spaceXs),
        PressScale(
          onTap: () => onReply(comment.id),
          child: DesignText(
            'Antworten',
            style: DesignTextStyle.label,
            color: tokens.primary,
          ),
        ),
      ],
    );

    final tile = Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
      child: body,
    );

    if (comment.children.isEmpty) return tile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile,
        Padding(
          padding: EdgeInsets.only(left: tokens.spaceXl),
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
