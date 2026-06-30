import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/feedback_models.dart';
import '../widgets/suggestion_card.dart';

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
    if (suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.feedback_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Noch keine Vorschläge vorhanden.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tippe auf „+", um einen Vorschlag zu erstellen.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    final sorted = List<FeedbackSuggestion>.from(suggestions)
      ..sort((a, b) => a.status.sortIndex.compareTo(b.status.sortIndex));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
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
