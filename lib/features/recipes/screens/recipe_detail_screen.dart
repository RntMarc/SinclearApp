import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/widgets/user_avatar.dart';
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
  bool? _bookmarked;
  bool _bookmarkToggling = false;
  bool _hasLoaded = false;
  List<RecipeReview>? _reviews;
  bool _loadingReviews = false;
  String? _reviewsError;
  final Map<String, UserBasePublic> _reviewUsers = {};

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
      final results = await Future.wait([
        scope.recipes.get(widget.id),
        scope.recipes.bookmarkStatus(widget.id),
        scope.recipes.getReviews(widget.id),
      ]);
      if (!mounted) return;
      final reviews = (results[2] as RecipeReviewListResponse).data;
      await _loadReviewUsers(reviews);
      if (!mounted) return;
      setState(() {
        _recipe = results[0] as RecipeDetail;
        _bookmarked = results[1] as bool;
        _reviews = reviews;
        _loading = false;
        _loadingReviews = false;
        _error = null;
        _reviewsError = null;
      });
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
    if (_bookmarkToggling || _bookmarked == null) return;
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezept löschen'),
        content: Text('${_recipe?.title} wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    try {
      await AppScope.of(context).recipes.delete(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rezept gelöscht.')));
      if (!mounted) return;
      context.go('/rezepte');
    } catch (e, st) {
      developer.log('Failed to delete recipe', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Löschen fehlgeschlagen.')));
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

  Future<void> _loadReviewsIfNeeded() async {
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

  Future<void> _showCreateReviewDialog() async {
    final result = await showDialog<({int rating, String? comment})>(
      context: context,
      builder: (_) => const _ReviewDialog(),
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
      _loadReviewsIfNeeded();
    } catch (e, st) {
      developer.log('Failed to create review', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern.')));
    }
  }

  Future<void> _showEditReviewDialog(RecipeReview review) async {
    final result = await showDialog<({int rating, String? comment})>(
      context: context,
      builder: (_) => _ReviewDialog(
        initialRating: review.rating,
        initialComment: review.comment,
      ),
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
      _loadReviewsIfNeeded();
    } catch (e, st) {
      developer.log('Failed to update review', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern.')));
    }
  }

  Future<void> _confirmDeleteReview(RecipeReview review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bewertung löschen'),
        content: const Text('Wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await AppScope.of(context).recipes.deleteReview(widget.id, review.id);
      if (!mounted) return;
      setState(() => _reviews = null);
      _loadReviewsIfNeeded();
    } catch (e, st) {
      developer.log('Failed to delete review', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Löschen fehlgeschlagen.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _recipe == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Unbekannter Fehler'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 600;
    final recipe = _recipe!;
    final auth = AppScope.of(context).auth;
    final currentUserId = auth.userId ?? '';
    final isOwner = currentUserId == recipe.creatorId;
    final canEdit = isOwner || auth.isAdmin;

    if (isWide) {
      return _WideDetail(
        recipe: recipe,
        canEdit: canEdit,
        bookmarked: _bookmarked ?? false,
        bookmarkToggling: _bookmarkToggling,
        onToggleBookmark: _toggleBookmark,
        onDelete: _delete,
        reviews: _reviews,
        loadingReviews: _loadingReviews,
        reviewsError: _reviewsError,
        currentUserId: currentUserId,
        reviewUsers: _reviewUsers,
        onLoadReviews: _loadReviewsIfNeeded,
        onCreateReview: _showCreateReviewDialog,
        onEditReview: _showEditReviewDialog,
        onDeleteReview: _confirmDeleteReview,
      );
    }
    return _NarrowDetail(
      recipe: recipe,
      canEdit: canEdit,
      bookmarked: _bookmarked ?? false,
      bookmarkToggling: _bookmarkToggling,
      onToggleBookmark: _toggleBookmark,
      onDelete: _delete,
      reviews: _reviews,
      loadingReviews: _loadingReviews,
      reviewsError: _reviewsError,
      currentUserId: currentUserId,
      reviewUsers: _reviewUsers,
      onLoadReviews: _loadReviewsIfNeeded,
      onCreateReview: _showCreateReviewDialog,
      onEditReview: _showEditReviewDialog,
      onDeleteReview: _confirmDeleteReview,
    );
  }
}

// ---------------------------------------------------------------------------
// Wide (Desktop) layout
// ---------------------------------------------------------------------------

class _WideDetail extends StatelessWidget {
  final RecipeDetail recipe;
  final bool canEdit;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDelete;
  final List<RecipeReview>? reviews;
  final bool loadingReviews;
  final String? reviewsError;
  final String currentUserId;
  final Map<String, UserBasePublic> reviewUsers;
  final VoidCallback onLoadReviews;
  final VoidCallback onCreateReview;
  final void Function(RecipeReview) onEditReview;
  final void Function(RecipeReview) onDeleteReview;

  const _WideDetail({
    required this.recipe,
    required this.canEdit,
    required this.bookmarked,
    required this.bookmarkToggling,
    required this.onToggleBookmark,
    required this.onDelete,
    required this.reviews,
    required this.loadingReviews,
    this.reviewsError,
    required this.currentUserId,
    required this.reviewUsers,
    required this.onLoadReviews,
    required this.onCreateReview,
    required this.onEditReview,
    required this.onDeleteReview,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackButton(),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _RecipeInfo(recipe: recipe)),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _ActionsCard(
                      canEdit: canEdit,
                      bookmarked: bookmarked,
                      bookmarkToggling: bookmarkToggling,
                      onToggleBookmark: onToggleBookmark,
                      onDelete: onDelete,
                    ),
                    const SizedBox(height: 16),
                    _ReviewsSection(
                      reviews: reviews,
                      loading: loadingReviews,
                      error: reviewsError,
                      currentUserId: currentUserId,
                      reviewUsers: reviewUsers,
                      onLoadReviews: onLoadReviews,
                      onCreateReview: onCreateReview,
                      onEditReview: onEditReview,
                      onDeleteReview: onDeleteReview,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Narrow (Mobile) layout
// ---------------------------------------------------------------------------

class _NarrowDetail extends StatelessWidget {
  final RecipeDetail recipe;
  final bool canEdit;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDelete;
  final List<RecipeReview>? reviews;
  final bool loadingReviews;
  final String? reviewsError;
  final String currentUserId;
  final Map<String, UserBasePublic> reviewUsers;
  final VoidCallback onLoadReviews;
  final VoidCallback onCreateReview;
  final void Function(RecipeReview) onEditReview;
  final void Function(RecipeReview) onDeleteReview;

  const _NarrowDetail({
    required this.recipe,
    required this.canEdit,
    required this.bookmarked,
    required this.bookmarkToggling,
    required this.onToggleBookmark,
    required this.onDelete,
    required this.reviews,
    required this.loadingReviews,
    this.reviewsError,
    required this.currentUserId,
    required this.reviewUsers,
    required this.onLoadReviews,
    required this.onCreateReview,
    required this.onEditReview,
    required this.onDeleteReview,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Row(
            children: [
              const BackButton(),
              Expanded(
                child: TabBar(
                  tabs: const [
                    Tab(text: 'Rezept'),
                    Tab(text: 'Bewertungen'),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _RecipeInfo(recipe: recipe),
                      const SizedBox(height: 16),
                      _ActionsCard(
                        canEdit: canEdit,
                        bookmarked: bookmarked,
                        bookmarkToggling: bookmarkToggling,
                        onToggleBookmark: onToggleBookmark,
                        onDelete: onDelete,
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _ReviewsSection(
                    reviews: reviews,
                    loading: loadingReviews,
                    error: reviewsError,
                    currentUserId: currentUserId,
                    reviewUsers: reviewUsers,
                    onLoadReviews: onLoadReviews,
                    onCreateReview: onCreateReview,
                    onEditReview: onEditReview,
                    onDeleteReview: onDeleteReview,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recipe info
// ---------------------------------------------------------------------------

class _RecipeInfo extends StatelessWidget {
  final RecipeDetail recipe;
  const _RecipeInfo({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = recipeCategoryIcons[recipe.category] ?? '🍴';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                recipe.title,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recipe.description != null && recipe.description!.isNotEmpty) ...[
          Text(recipe.description!, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
        ],
        _InfoRow(Icons.restaurant_rounded, recipe.categoryLabel),
        _InfoRow(Icons.group_rounded, '${recipe.servings} Portionen'),
        if (recipe.avgRating != null)
          _InfoRow(
            Icons.star_rounded,
            '${recipe.avgRating!.toStringAsFixed(1)} / 5 (${recipe.ratingCount} Bewertungen)',
          ),
        if (recipe.dietaryTags != null && recipe.dietaryTags!.isNotEmpty)
          _InfoRow(Icons.local_dining_rounded, recipe.dietaryTags!),
        _InfoRow(Icons.calendar_today_rounded, recipe.createdAt.substring(0, 10)),
        const SizedBox(height: 16),
        if (recipe.ingredients.isNotEmpty) ...[
          Text(
            'Zutaten',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: recipe.ingredients.map((ing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ing.name,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${ing.amount % 1 == 0 ? ing.amount.toInt() : ing.amount} ${ing.unit}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (recipe.steps.isNotEmpty) ...[
          Text(
            'Zubereitung',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...recipe.steps.map((step) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            step.categoryLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        if (step.title != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step.title!,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(step.description, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Actions card
// ---------------------------------------------------------------------------

class _ActionsCard extends StatelessWidget {
  final bool canEdit;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDelete;

  const _ActionsCard({
    required this.canEdit,
    required this.bookmarked,
    required this.bookmarkToggling,
    required this.onToggleBookmark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.tonalIcon(
              onPressed: bookmarkToggling ? null : onToggleBookmark,
              icon: bookmarkToggling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
              label: Text(
                bookmarkToggling
                    ? '…'
                    : bookmarked
                    ? 'Lesezeichen entfernen'
                    : 'Lesezeichen setzen',
              ),
            ),
            if (canEdit) ...[
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  final recipe = context
                      .findAncestorStateOfType<_RecipeDetailScreenState>()
                      ?._recipe;
                  if (recipe != null) {
                    context.go('/rezepte/${recipe.id}/bearbeiten');
                  }
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Bearbeiten'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Rezept löschen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reviews section
// ---------------------------------------------------------------------------

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
    final theme = Theme.of(context);

    if (loading && reviews == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && reviews == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(error!),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onLoadReviews,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final items = reviews ?? <RecipeReview>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Bewertungen', style: theme.textTheme.titleMedium),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: onCreateReview,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Schreiben'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Noch keine Bewertungen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ...items.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reviewUser != null) ...[
              InkWell(
                onTap: () => context.go('/kontakte/${review.userId}'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      UserAvatar(
                        imageUrl: reviewUser!.image,
                        displayName: reviewUser!.displayName,
                        radius: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        reviewUser!.displayName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Bearbeiten',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_rounded,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Löschen',
                  ),
                ],
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(review.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
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
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Review dialog
// ---------------------------------------------------------------------------

class _ReviewDialog extends StatefulWidget {
  final int? initialRating;
  final String? initialComment;

  const _ReviewDialog({this.initialRating, this.initialComment});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
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
    final isEditing = widget.initialRating != null;
    return AlertDialog(
      title: Text(isEditing ? 'Bewertung bearbeiten' : 'Bewertung schreiben'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return IconButton(
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: filled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _rating = i + 1),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Kommentar (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _rating == 0
              ? null
              : () => Navigator.pop(context, (
                  rating: _rating,
                  comment: _commentController.text.trim().isEmpty
                      ? null
                      : _commentController.text.trim(),
                )),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
