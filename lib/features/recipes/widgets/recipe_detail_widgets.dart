import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../user/models/user_models.dart';
import '../models/recipes_models.dart';

class RecipeContent extends StatelessWidget {
  final RecipeDetail recipe;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onToggleBookmark;

  const RecipeContent({super.key,
    required this.recipe,
    required this.bookmarked,
    required this.bookmarkToggling,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recipe.image != null && recipe.image!.isNotEmpty)
            RecipeImage(image: recipe.image!, tokens: tokens),
          DesignText(
            recipe.title,
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceSm),
          if (recipe.description != null && recipe.description!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
              child: DesignText(
                recipe.description!,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
            ),
          SizedBox(height: tokens.spaceMd),
          Wrap(
            spacing: tokens.spaceSm,
            runSpacing: tokens.spaceXs,
            children: [
              metaChip(
                recipeCategoryIcons[recipe.category] ?? '🍴',
                recipe.categoryLabel,
                tokens,
              ),
              if (recipe.dietaryTags != null && recipe.dietaryTags!.isNotEmpty)
                metaChip('🥗', recipe.dietaryTags!, tokens),
              metaChip('👤', '${recipe.servings} Portionen', tokens),
              if (recipe.avgRating != null)
                metaChip(
                  '⭐',
                  '${recipe.avgRating!.toStringAsFixed(1)} (${recipe.ratingCount})',
                  tokens,
                ),
            ],
          ),
          SizedBox(height: tokens.spaceLg),
          DesignButton(
            variant: DesignButtonVariant.filled,
            icon: bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: bookmarkToggling
                ? '…'
                : bookmarked
                    ? 'Lesezeichen entfernen'
                    : 'Lesezeichen setzen',
            loading: bookmarkToggling,
            onPressed: bookmarkToggling ? null : onToggleBookmark,
          ),
          SizedBox(height: tokens.spaceXl),
          if (recipe.ingredients.isNotEmpty) ...[
            DesignText(
              'Zutaten',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceMd),
            DesignCard(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: Column(
                children: [
                  for (int i = 0; i < recipe.ingredients.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 0,
                        thickness: 1,
                        color: tokens.border.withValues(alpha: 0.3),
                      ),
                    ingredientRow(recipe.ingredients[i], tokens),
                  ],
                ],
              ),
            ),
            SizedBox(height: tokens.spaceXl),
          ],
          if (recipe.steps.isNotEmpty) ...[
            DesignText(
              'Zubereitung',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceMd),
            ..._groupedSteps.entries.map(
              (entry) => Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DesignText(
                      stepCategories[entry.key] ?? entry.key,
                      style: DesignTextStyle.body,
                      color: tokens.primary,
                    ),
                    SizedBox(height: tokens.spaceSm),
                    ...entry.value.map(
                      (step) => stepCard(step, tokens),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: tokens.spaceXl),
          ],
          metaRow('Kategorie', recipe.categoryLabel, tokens),
          metaRow('Erstellt', _formatDate(recipe.createdAt), tokens),
          metaRow('Aktualisiert', _formatDate(recipe.updatedAt), tokens),
          SizedBox(height: tokens.spaceXl),
        ],
      ),
    );
  }

  Map<String, List<RecipeStep>> get _groupedSteps {
    final map = <String, List<RecipeStep>>{};
    for (final step in recipe.steps) {
      map.putIfAbsent(step.category, () => []).add(step);
    }
    return map;
  }

  String _formatDate(String iso) {
    try {
      final dt = parseApiDate(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }
}

Widget metaChip(String emoji, String label, DesignTokens tokens) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm, vertical: tokens.spaceXs),
    decoration: BoxDecoration(
      color: tokens.surfaceVariant,
      borderRadius: BorderRadius.circular(tokens.radiusPill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        SizedBox(width: tokens.spaceXs),
        DesignText(
          label,
          style: DesignTextStyle.label,
          color: tokens.textHigh,
        ),
      ],
    ),
  );
}

Widget metaRow(String label, String value, DesignTokens tokens) {
  return Padding(
    padding: EdgeInsets.only(bottom: tokens.spaceXs),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: DesignText(
            label,
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ),
        DesignText(
          value,
          style: DesignTextStyle.label,
          color: tokens.textHigh,
        ),
      ],
    ),
  );
}

class RecipeImage extends StatelessWidget {
  final String image;
  final DesignTokens tokens;

  const RecipeImage({super.key, required this.image, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final widget = _buildImage(context);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceLg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: widget,
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (image.startsWith('data:')) {
      try {
        final data = image.contains(',')
            ? image.substring(image.indexOf(',') + 1)
            : image;
        final bytes = base64Decode(data);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _imagePlaceholder,
        );
      } catch (_) {
        return _imagePlaceholder;
      }
    }
    return CachedNetworkImage(
      imageUrl: image,
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      placeholder: (_, _) => _imagePlaceholder,
      errorWidget: (_, _, _) => _imagePlaceholder,
    );
  }

  Widget get _imagePlaceholder => Container(
    height: 220,
    color: tokens.surfaceVariant,
    child: Center(
      child: Icon(Icons.image_rounded, size: 48, color: tokens.textLow),
    ),
  );
}

Widget ingredientRow(RecipeIngredient ingredient, DesignTokens tokens) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
    child: Row(
      children: [
        SizedBox(
          width: 64,
          child: DesignText(
            '${formatAmount(ingredient.amount)} ${ingredient.unit}',
            style: DesignTextStyle.body,
            color: tokens.textHigh,
          ),
        ),
        SizedBox(width: tokens.spaceMd),
        Expanded(
          child: DesignText(
            ingredient.name,
            style: DesignTextStyle.body,
            color: tokens.textHigh,
          ),
        ),
      ],
    ),
  );
}

String formatAmount(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toInt().toString();
  }
  return amount.toStringAsFixed(1);
}

Widget stepCard(RecipeStep step, DesignTokens tokens) {
  return Padding(
    padding: EdgeInsets.only(bottom: tokens.spaceSm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: tokens.spaceXs),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: tokens.primary,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step.title != null && step.title!.isNotEmpty)
                DesignText(
                  step.title!,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                ),
              DesignText(
                step.description,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class RecipeReviewsSection extends StatelessWidget {
  final List<RecipeReview>? reviews;
  final bool loading;
  final String? error;
  final String currentUserId;
  final Map<String, UserBasePublic> reviewUsers;
  final VoidCallback onLoadReviews;
  final VoidCallback onCreateReview;
  final void Function(RecipeReview) onEditReview;
  final void Function(RecipeReview) onDeleteReview;

  const RecipeReviewsSection({super.key,
    required this.reviews,
    required this.loading,
    this.error,
    required this.currentUserId,
    required this.reviewUsers,
    required this.onLoadReviews,
    required this.onCreateReview,
    required this.onEditReview,
    required this.onDeleteReview,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (loading && reviews == null) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (error != null && reviews == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.danger),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              error!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceLg),
            DesignButton(
              variant: DesignButtonVariant.filled,
              label: 'Erneut versuchen',
              onPressed: onLoadReviews,
            ),
          ],
        ),
      );
    }

    final items = reviews ?? <RecipeReview>[];

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DesignText(
                'Bewertungen',
                style: DesignTextStyle.subtitle,
                color: tokens.textHigh,
              ),
              const Spacer(),
              DesignButton(
                variant: DesignButtonVariant.filled,
                icon: Icons.add_rounded,
                label: 'Schreiben',
                onPressed: onCreateReview,
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMd),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceXl),
              child: Center(
                child: DesignText(
                  'Noch keine Bewertungen.',
                  style: DesignTextStyle.body,
                  color: tokens.textLow,
                ),
              ),
            )
          else
            ...items.map(
              (review) => Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceMd),
                child: RecipeReviewCard(
                  review: review,
                  isOwn: review.userId == currentUserId,
                  reviewUser: reviewUsers[review.userId],
                  onEdit: () => onEditReview(review),
                  onDelete: () => onDeleteReview(review),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RecipeReviewCard extends StatelessWidget {
  final RecipeReview review;
  final bool isOwn;
  final UserBasePublic? reviewUser;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RecipeReviewCard({super.key,
    required this.review,
    required this.isOwn,
    this.reviewUser,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reviewUser != null) ...[
            GestureDetector(
              onTap: () => context.go('/kontakte/${review.userId}'),
              child: Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceSm),
                child: Row(
                  children: [
                    DesignAvatar(
                      imageUrl: reviewUser!.image,
                      name: reviewUser!.displayName,
                      size: 28,
                    ),
                    SizedBox(width: tokens.spaceSm),
                    DesignText(
                      reviewUser!.displayName,
                      style: DesignTextStyle.body,
                      color: tokens.textHigh,
                    ),
                  ],
                ),
              ),
            ),
          ],
          Row(
            children: [
              RecipeStarRating(rating: review.rating, size: 16),
              const Spacer(),
              if (isOwn) ...[
                DesignIconButton(
                  icon: Icons.edit_rounded,
                  onPressed: onEdit,
                ),
                DesignIconButton(
                  icon: Icons.delete_rounded,
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            SizedBox(height: tokens.spaceSm),
            DesignText(
              review.comment!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
          ],
          SizedBox(height: tokens.spaceXs),
          DesignText(
            _formatDate(review.createdAt),
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = parseApiDate(iso);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }
}

class RecipeStarRating extends StatelessWidget {
  final int rating;
  final double size;

  const RecipeStarRating({super.key, required this.rating, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: tokens.primary,
        ),
      ),
    );
  }
}

class RecipeReviewForm extends StatefulWidget {
  final int? initialRating;
  final String? initialComment;

  const RecipeReviewForm({super.key, this.initialRating, this.initialComment});

  @override
  State<RecipeReviewForm> createState() => _RecipeReviewFormState();
}

class _RecipeReviewFormState extends State<RecipeReviewForm> {
  int _rating = 0;
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating ?? 0;
    _commentController = TextEditingController(
      text: widget.initialComment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final isEditing = widget.initialRating != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DesignText(
                  isEditing ? 'Bewertung bearbeiten' : 'Bewertung schreiben',
                  style: DesignTextStyle.title,
                  color: tokens.textHigh,
                ),
              ),
              DesignIconButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return DesignIconButton(
                icon: filled ? Icons.star_rounded : Icons.star_border_rounded,
                onPressed: () => setState(() => _rating = i + 1),
              );
            }),
          ),
          SizedBox(height: tokens.spaceMd),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMd,
              vertical: tokens.spaceSm,
            ),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              border: Border.all(
                color: tokens.border.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Kommentar (optional)',
                  labelStyle: TextStyle(color: tokens.textLow, fontSize: 15),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                style: TextStyle(color: tokens.textHigh, fontSize: 15),
                cursorColor: tokens.primary,
                maxLines: 3,
              ),
            ),
          ),
          SizedBox(height: tokens.spaceLg),
          DesignButton(
            variant: DesignButtonVariant.filled,
            label: 'Speichern',
            fullWidth: true,
            onPressed: _rating == 0
                ? null
                : () => Navigator.pop(context, (
                    rating: _rating,
                    comment: _commentController.text.trim().isEmpty
                        ? null
                        : _commentController.text.trim(),
                  )),
          ),
        ],
      ),
    );
  }
}
