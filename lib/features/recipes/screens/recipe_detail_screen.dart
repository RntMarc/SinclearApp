import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../user/models/user_models.dart';
import '../models/recipes_models.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String id;

  const RecipeDetailScreen({super.key, required this.id});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  RecipeDetail? _recipe;
  bool _loading = true;
  String? _error;
  bool _hasLoaded = false;

  bool? _bookmarked;
  bool _bookmarkToggling = false;

  List<RecipeReview>? _reviews;
  bool _loadingReviews = false;
  String? _reviewsError;
  final Map<String, UserBasePublic> _reviewUsers = {};

  String get _currentUserId => AppScope.of(context).auth.userId ?? '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final scope = AppScope.of(context);
      await scope.auth.getAccessToken();
      final (recipe, bookmarked) = await (
        scope.recipes.get(widget.id),
        scope.recipes.bookmarkStatus(widget.id),
      ).wait;
      if (!mounted) return;
      setState(() {
        _recipe = recipe;
        _bookmarked = bookmarked;
        _loading = false;
        _error = null;
      });
      _loadReviews();
    } catch (e, st) {
      developer.log('Failed to load recipe', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Rezept konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkToggling || _bookmarked == null || _recipe == null) return;
    setState(() => _bookmarkToggling = true);
    try {
      final recipes = AppScope.of(context).recipes;
      if (_bookmarked!) {
        await recipes.removeBookmark(widget.id);
      } else {
        await recipes.setBookmark(widget.id);
      }
      if (!mounted) return;
      setState(() {
        _bookmarked = !_bookmarked!;
        _bookmarkToggling = false;
      });
    } catch (e, st) {
      developer.log('Failed to toggle bookmark', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _bookmarkToggling = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _loadingReviews = true);
    try {
      final result = await AppScope.of(context).recipes.getReviews(widget.id);
      if (!mounted) return;
      await _loadReviewUsers(result.data);
      if (!mounted) return;
      setState(() {
        _reviews = result.data;
        _loadingReviews = false;
        _reviewsError = null;
      });
    } catch (e, st) {
      developer.log('Failed to load reviews', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingReviews = false;
        _reviewsError = 'Bewertungen konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadReviewUsers(List<RecipeReview> reviews) async {
    try {
      final users = await AppScope.of(context).user.listAll();
      if (!mounted) return;
      for (final user in users) {
        _reviewUsers[user.id] = user;
      }
    } catch (_) {}
  }

  Future<void> _showCreateReviewDialog() async {
    final result = await _showReviewSheet(
      initialRating: null,
      initialComment: null,
    );
    if (result == null || !mounted) return;
    try {
      await AppScope.of(context).recipes.createReview(
        widget.id,
        rating: result.rating,
        comment: result.comment,
      );
      if (!mounted) return;
      setState(() => _reviews = null);
      _loadReviews();
    } catch (e, st) {
      developer.log('Failed to create review', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Speichern.')),
      );
    }
  }

  Future<void> _showEditReviewDialog(RecipeReview review) async {
    final result = await _showReviewSheet(
      initialRating: review.rating,
      initialComment: review.comment,
    );
    if (result == null || !mounted) return;
    try {
      await AppScope.of(context).recipes.updateReview(
        widget.id,
        review.id,
        rating: result.rating,
        comment: result.comment,
      );
      if (!mounted) return;
      setState(() => _reviews = null);
      _loadReviews();
    } catch (e, st) {
      developer.log('Failed to update review', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Speichern.')),
      );
    }
  }

  Future<({int rating, String? comment})?> _showReviewSheet({
    int? initialRating,
    String? initialComment,
  }) {
    return showDesignSheet<({int rating, String? comment})>(
      context: context,
      child: _ReviewForm(
        initialRating: initialRating,
        initialComment: initialComment,
      ),
    );
  }

  Future<void> _confirmDeleteReview(RecipeReview review) async {
    final tokens = DesignTheme.of(context);
    final confirm = await showDesignSheet<bool>(
      context: context,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesignText(
              'Bewertung löschen',
              style: DesignTextStyle.title,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceMd),
            DesignText(
              'Wirklich löschen?',
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceLg),
            Row(
              children: [
                Expanded(
                  child: DesignButton(
                    variant: DesignButtonVariant.outlined,
                    label: 'Abbrechen',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: DesignButton(
                    variant: DesignButtonVariant.filled,
                    label: 'Löschen',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await AppScope.of(context).recipes.deleteReview(widget.id, review.id);
      if (!mounted) return;
      setState(() => _reviews = null);
      _loadReviews();
    } catch (e, st) {
      developer.log('Failed to delete review', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Löschen fehlgeschlagen.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Column(
        children: [
          DesignAppBar(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: _recipe?.title ?? 'Rezept',
            actions: [
              DesignIconButton(
                icon: _bookmarked == true
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                onPressed: _bookmarkToggling ? null : _toggleBookmark,
              ),
            ],
          ),
          Expanded(
            child: _buildBody(tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DesignTokens tokens) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_error != null || _recipe == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.danger),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              _error ?? 'Unbekannter Fehler',
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceLg),
            DesignButton(
              variant: DesignButtonVariant.filled,
              label: 'Erneut versuchen',
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(right: tokens.spaceSm),
            child: TabBar(
              indicatorColor: tokens.primary,
              labelColor: tokens.textHigh,
              unselectedLabelColor: tokens.textLow,
              labelStyle: tokens.bodyStyle(tokens.textHigh),
              unselectedLabelStyle: tokens.labelStyle(tokens.textLow),
              tabs: const [
                Tab(text: 'Rezept'),
                Tab(text: 'Bewertungen'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _RecipeContent(
                  recipe: _recipe!,
                  bookmarked: _bookmarked ?? false,
                  bookmarkToggling: _bookmarkToggling,
                  onToggleBookmark: _toggleBookmark,
                ),
                _ReviewsSection(
                  reviews: _reviews,
                  loading: _loadingReviews,
                  error: _reviewsError,
                  currentUserId: _currentUserId,
                  reviewUsers: _reviewUsers,
                  onLoadReviews: _loadReviews,
                  onCreateReview: _showCreateReviewDialog,
                  onEditReview: _showEditReviewDialog,
                  onDeleteReview: _confirmDeleteReview,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeContent extends StatelessWidget {
  final RecipeDetail recipe;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onToggleBookmark;

  const _RecipeContent({
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
            _RecipeImage(image: recipe.image!, tokens: tokens),
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
              _metaChip(
                recipeCategoryIcons[recipe.category] ?? '🍴',
                recipe.categoryLabel,
                tokens,
              ),
              if (recipe.dietaryTags != null && recipe.dietaryTags!.isNotEmpty)
                _metaChip('🥗', recipe.dietaryTags!, tokens),
              _metaChip('👤', '${recipe.servings} Portionen', tokens),
              if (recipe.avgRating != null)
                _metaChip(
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
                    _ingredientRow(recipe.ingredients[i], tokens),
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
                      (step) => _stepCard(step, tokens),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: tokens.spaceXl),
          ],
          _metaRow('Kategorie', recipe.categoryLabel, tokens),
          _metaRow('Erstellt', _formatDate(recipe.createdAt), tokens),
          _metaRow('Aktualisiert', _formatDate(recipe.updatedAt), tokens),
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

Widget _metaChip(String emoji, String label, DesignTokens tokens) {
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

Widget _metaRow(String label, String value, DesignTokens tokens) {
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

class _RecipeImage extends StatelessWidget {
  final String image;
  final DesignTokens tokens;

  const _RecipeImage({required this.image, required this.tokens});

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
    return Image.network(
      image,
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _imagePlaceholder,
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

Widget _ingredientRow(RecipeIngredient ingredient, DesignTokens tokens) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
    child: Row(
      children: [
        SizedBox(
          width: 64,
          child: DesignText(
            '${_formatAmount(ingredient.amount)} ${ingredient.unit}',
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

String _formatAmount(double amount) {
  if (amount == amount.roundToDouble()) {
    return amount.toInt().toString();
  }
  return amount.toStringAsFixed(1);
}

Widget _stepCard(RecipeStep step, DesignTokens tokens) {
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

class _ReviewsSection extends StatelessWidget {
  final List<RecipeReview>? reviews;
  final bool loading;
  final String? error;
  final String currentUserId;
  final Map<String, UserBasePublic> reviewUsers;
  final VoidCallback onLoadReviews;
  final VoidCallback onCreateReview;
  final void Function(RecipeReview) onEditReview;
  final void Function(RecipeReview) onDeleteReview;

  const _ReviewsSection({
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
                child: _ReviewCard(
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

class _ReviewCard extends StatelessWidget {
  final RecipeReview review;
  final bool isOwn;
  final UserBasePublic? reviewUser;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReviewCard({
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
              _StarRating(rating: review.rating, size: 16),
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

class _StarRating extends StatelessWidget {
  final int rating;
  final double size;

  const _StarRating({required this.rating, this.size = 20});

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

class _ReviewForm extends StatefulWidget {
  final int? initialRating;
  final String? initialComment;

  const _ReviewForm({this.initialRating, this.initialComment});

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
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
