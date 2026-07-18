import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/composite/comment_input.dart';
import '../models/feedback_models.dart';
import 'comment_tile.dart';

class FeedbackSuggestionCard extends StatelessWidget {
  final FeedbackSuggestion suggestion;
  final bool hasVoted;
  final int upvoteCount;
  final Color statusColor;
  final VoidCallback onVote;

  const FeedbackSuggestionCard({
    super.key,
    required this.suggestion,
    required this.hasVoted,
    required this.upvoteCount,
    required this.statusColor,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DesignText(
                  suggestion.title,
                  style: DesignTextStyle.title,
                  color: tokens.textHigh,
                ),
              ),
              SizedBox(width: tokens.spaceMd),
              DesignBadge(
                label: suggestion.status.label,
                color: statusColor,
              ),
            ],
          ),
          SizedBox(height: tokens.spaceLg),
          Row(
            children: [
              DesignButton(
                variant: hasVoted
                    ? DesignButtonVariant.filled
                    : DesignButtonVariant.outlined,
                icon: hasVoted
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined,
                label: '$upvoteCount',
                onPressed: onVote,
              ),
              SizedBox(width: tokens.spaceLg),
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: tokens.textLow.withValues(alpha: 0.6),
              ),
              SizedBox(width: tokens.spaceXs),
              DesignText(
                'Erstellt ${app_date.formatRelativeDate(suggestion.createdAt)}',
                style: DesignTextStyle.label,
                color: tokens.textLow.withValues(alpha: 0.7),
              ),
            ],
          ),
          if (suggestion.description != null &&
              suggestion.description!.isNotEmpty) ...[
            SizedBox(height: tokens.spaceLg),
            DesignText(
              'Beschreibung',
              style: DesignTextStyle.subtitle,
              color: tokens.primary,
            ),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              suggestion.description!,
              style: DesignTextStyle.body,
            ),
          ],
        ],
      ),
    );
  }
}

class FeedbackAdminActions extends StatelessWidget {
  final FeedbackStatus currentStatus;
  final ValueChanged<FeedbackStatus> onStatusChanged;

  const FeedbackAdminActions({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            'Admin-Aktionen',
            style: DesignTextStyle.subtitle,
            color: tokens.primary,
          ),
          SizedBox(height: tokens.spaceMd),
          Wrap(
            spacing: tokens.spaceSm,
            runSpacing: tokens.spaceSm,
            children: FeedbackStatus.values.map((status) {
              final isActive = status == currentStatus;
              return DesignChip(
                label: status.label,
                selected: isActive,
                onTap: isActive ? null : () => onStatusChanged(status),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class FeedbackCommentsCard extends StatelessWidget {
  final String? replyToId;
  final bool commentsLoading;
  final List<FeedbackComment> comments;
  final String currentUserId;
  final bool isAdmin;
  final int commentCount;
  final ValueChanged<String> onReply;
  final void Function(String text, {String? parentId}) onAddComment;
  final void Function(String id) onEdit;
  final void Function(String id) onDelete;
  final String Function(String userId) resolveUserName;

  const FeedbackCommentsCard({
    super.key,
    this.replyToId,
    required this.commentsLoading,
    required this.comments,
    required this.currentUserId,
    required this.isAdmin,
    required this.commentCount,
    required this.onReply,
    required this.onAddComment,
    required this.onEdit,
    required this.onDelete,
    required this.resolveUserName,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DesignText(
                'Kommentare',
                style: DesignTextStyle.subtitle,
                color: tokens.primary,
              ),
              SizedBox(width: tokens.spaceSm),
              DesignText(
                '$commentCount',
                style: DesignTextStyle.label,
                color: tokens.textLow,
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMd),
          if (replyToId == null)
            CommentInput(
              hintText: 'Kommentar hinzufügen...',
              onSubmit: (text) => onAddComment(text),
            )
          else
            CommentInput(
              hintText: 'Antworten...',
              autofocus: true,
              onSubmit: (text) => onAddComment(text, parentId: replyToId),
              onCancel: () => onReply(''),
            ),
          SizedBox(height: tokens.spaceMd),
          if (commentsLoading)
            const Center(child: CircularProgressIndicator())
          else if (comments.isEmpty)
            Center(
              child: DesignText(
                'Noch keine Kommentare.',
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
            )
          else
            ...comments.map(
              (comment) => Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceSm),
                child: CommentTile(
                  comment: comment,
                  currentUserId: currentUserId,
                  isAdmin: isAdmin,
                  resolveUserName: resolveUserName,
                  onReply: onReply,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
