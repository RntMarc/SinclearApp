import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../models/feedback_models.dart';
import '../widgets/suggestion_card.dart';

/// Scrollable list of [FeedbackSuggestion] cards, sorted by status.
class SuggestionList extends StatelessWidget {
  final List<FeedbackSuggestion> suggestions;
  final String currentUserId;
  final bool isAdmin;
  final ValueChanged<FeedbackSuggestion> onVote;
  final ValueChanged<FeedbackSuggestion> onDelete;

  const SuggestionList({
    super.key,
    required this.suggestions,
    required this.currentUserId,
    required this.isAdmin,
    required this.onVote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.feedback_outlined,
              size: 48,
              color: tokens.textLow,
            ),
            SizedBox(height: tokens.spaceMd),
            DesignText(
              'Noch keine Vorschläge vorhanden.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
            SizedBox(height: tokens.spaceXs),
            DesignText(
              'Tippe auf „+", um einen Vorschlag zu erstellen.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          ],
        ),
      );
    }

    final sorted = List<FeedbackSuggestion>.from(suggestions)
      ..sort((a, b) => a.status.sortIndex.compareTo(b.status.sortIndex));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final suggestion = sorted[index];
        return SuggestionCard(
          suggestion: suggestion,
          isOwner: suggestion.userId == currentUserId,
          isAdmin: isAdmin,
          onTap: () => context.push('/feedback/${suggestion.id}'),
          onVote: () => onVote(suggestion),
          onDelete: () => onDelete(suggestion),
        );
      },
    );
  }
}
