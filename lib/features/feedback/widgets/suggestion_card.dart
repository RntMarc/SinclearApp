import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../models/feedback_models.dart';

/// A single feedback suggestion rendered as a tappable catalog card.
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

  Color _statusColor(DesignTokens tokens, FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.submitted:
        return tokens.textLow;
      case FeedbackStatus.planned:
        return Colors.blue;
      case FeedbackStatus.next:
        return Colors.orange;
      case FeedbackStatus.inProgress:
        return Colors.amber.shade700;
      case FeedbackStatus.done:
        return tokens.success;
      case FeedbackStatus.cancelled:
      case FeedbackStatus.rejected:
        return tokens.danger;
      case FeedbackStatus.later:
        return Colors.purple;
    }
  }

  void _openMenu(BuildContext context) {
    final tokens = DesignTheme.of(context);
    showDesignSheet(
      context: context,
      child: DesignListTile(
        leading: Icon(
          Icons.delete_outline_rounded,
          color: tokens.danger,
          size: 20,
        ),
        title: 'Löschen',
        onTap: () {
          Navigator.of(context).pop();
          onDelete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final statusColor = _statusColor(tokens, suggestion.status);

    final vote = PressScale(
      onTap: onVote,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            suggestion.hasVoted
                ? Icons.thumb_up_rounded
                : Icons.thumb_up_outlined,
            size: 18,
            color: suggestion.hasVoted ? tokens.primary : tokens.textLow,
          ),
          SizedBox(width: tokens.spaceXs),
          DesignText(
            '${suggestion.upvoteCount}',
            style: DesignTextStyle.label,
            color: suggestion.hasVoted ? tokens.primary : tokens.textHigh,
          ),
        ],
      ),
    );

    return DesignCard(
      onTap: onTap,
      margin: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceXs,
      ),
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
                  style: DesignTextStyle.subtitle,
                  color: tokens.textHigh,
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              DesignBadge(
                label: suggestion.status.label,
                color: statusColor,
              ),
            ],
          ),
          if (suggestion.description != null &&
              suggestion.description!.isNotEmpty) ...[
            SizedBox(height: tokens.spaceSm),
            DesignText(
              suggestion.description!,
              style: DesignTextStyle.body,
              color: tokens.textLow,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: tokens.spaceMd),
          Row(
            children: [
              vote,
              SizedBox(width: tokens.spaceLg),
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: tokens.textLow.withValues(alpha: 0.6),
              ),
              SizedBox(width: tokens.spaceXs),
              DesignText(
                app_date.formatRelativeDate(suggestion.createdAt),
                style: DesignTextStyle.label,
                color: tokens.textLow.withValues(alpha: 0.7),
              ),
              const Spacer(),
              if (isOwner || isAdmin)
                DesignIconButton(
                  icon: Icons.more_vert_rounded,
                  onPressed: () => _openMenu(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
