import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../user/models/user_models.dart';
import '../models/recipes_models.dart';
import '../widgets/recipe_detail_widgets.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern.')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern.')));
    }
  }

  Future<({int rating, String? comment})?> _showReviewSheet({
    int? initialRating,
    String? initialComment,
  }) {
    return showDesignSheet<({int rating, String? comment})>(
      context: context,
      child: RecipeReviewForm(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Löschen fehlgeschlagen.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
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
          Expanded(child: _buildBody(tokens)),
        ],
      ),
    );
  }

  Widget _buildBody(DesignTokens tokens) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_error != null || _recipe == null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Center(
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
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: DefaultTabController(
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
                  RecipeContent(
                    recipe: _recipe!,
                    bookmarked: _bookmarked ?? false,
                    bookmarkToggling: _bookmarkToggling,
                    onToggleBookmark: _toggleBookmark,
                  ),
                  RecipeReviewsSection(
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
      ),
    );
  }
}
