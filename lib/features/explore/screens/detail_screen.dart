import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../user/models/user_models.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../models/explore_models.dart';
import '../widgets/detail_widgets.dart';

class DetailScreen extends StatefulWidget {
  final String id;

  const DetailScreen({super.key, required this.id});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  ExplorePlace? _place;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  bool? _bookmarked;
  bool _bookmarkToggling = false;
  bool _hasLoaded = false;
  List<Review>? _reviews;
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
      final (place, bookmarked, reviewsResponse) = await (
        scope.explore.get(widget.id),
        scope.explore.bookmarkStatus(widget.id),
        scope.explore.getReviews(widget.id),
      ).wait;
      if (!mounted) return;
      final reviews = reviewsResponse.data;
      await _loadReviewUsers(reviews);
      if (!mounted) return;
      setState(() {
        _place = place;
        _bookmarked = bookmarked;
        _reviews = reviews;
        _loading = false;
        _loadingReviews = false;
        _error = null;
        _reviewsError = null;
      });
    } catch (e, st) {
      developer.log('Failed to load place', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Ort konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkToggling || _bookmarked == null) return;
    setState(() => _bookmarkToggling = true);
    try {
      final explore = AppScope.of(context).explore;
      if (_bookmarked!) {
        await explore.removeBookmark(widget.id);
      } else {
        await explore.setBookmark(widget.id);
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

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final explore = AppScope.of(context).explore;
      final place = await explore.update(widget.id);
      if (!mounted) return;
      setState(() {
        _place = place;
        _refreshing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OSM-Daten aktualisiert.')));
    } catch (e, st) {
      developer.log('Failed to refresh place', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _refreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktualisierung fehlgeschlagen.')),
      );
    }
  }

  Future<void> _delete() async {
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
              'Ort löschen',
              style: DesignTextStyle.title,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceMd),
            DesignText(
              '${_place?.name} wirklich löschen?',
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
    if (confirm != true) return;
    if (!mounted) return;
    try {
      final explore = AppScope.of(context).explore;
      await explore.delete(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ort gelöscht.')));
      if (!mounted) return;
      context.pop();
    } catch (e, st) {
      developer.log('Failed to delete place', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Löschen fehlgeschlagen.')));
    }
  }

  Future<void> _loadReviewUsers(List<Review> reviews) async {
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
      final result = await AppScope.of(context).explore.getReviews(widget.id);
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
    final result = await _showReviewSheet(initialRating: null, initialComment: null);
    if (result == null || !mounted) return;
    try {
      await AppScope.of(context).explore.createReview(
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

  Future<void> _showEditReviewDialog(Review review) async {
    final result = await _showReviewSheet(
      initialRating: review.rating,
      initialComment: review.comment,
    );
    if (result == null || !mounted) return;
    try {
      await AppScope.of(context).explore.updateReview(
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

  Future<({int rating, String? comment})?> _showReviewSheet({
    int? initialRating,
    String? initialComment,
  }) {
    return showDesignSheet<({int rating, String? comment})>(
      context: context,
      child: PlaceReviewForm(
        initialRating: initialRating,
        initialComment: initialComment,
      ),
    );
  }

  Future<void> _confirmDeleteReview(Review review) async {
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
      await AppScope.of(context).explore.deleteReview(widget.id, review.id);
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
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: _place?.name ?? 'Details',
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

    if (_error != null || _place == null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceXl),
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
        ),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 600;
    final place = _place!;
    final auth = AppScope.of(context).auth;
    final currentUserId = auth.userId ?? '';
    final isOwner = currentUserId == place.creatorId;
    final canDelete = isOwner || auth.isAdmin;

    if (isWide) {
      return RefreshIndicator(
        onRefresh: _load,
        child: PlaceDetailWide(
          place: place,
          canDelete: canDelete,
          refreshing: _refreshing,
          bookmarked: _bookmarked ?? false,
          bookmarkToggling: _bookmarkToggling,
          onRefresh: _refresh,
          onDelete: _delete,
          onToggleBookmark: _toggleBookmark,
          reviews: _reviews,
          loadingReviews: _loadingReviews,
          reviewsError: _reviewsError,
          currentUserId: currentUserId,
          reviewUsers: _reviewUsers,
          onLoadReviews: _loadReviewsIfNeeded,
          onCreateReview: _showCreateReviewDialog,
          onEditReview: _showEditReviewDialog,
          onDeleteReview: _confirmDeleteReview,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: PlaceDetailNarrow(
        place: place,
        canDelete: canDelete,
        refreshing: _refreshing,
        bookmarked: _bookmarked ?? false,
        bookmarkToggling: _bookmarkToggling,
        onRefresh: _refresh,
        onDelete: _delete,
        onToggleBookmark: _toggleBookmark,
        reviews: _reviews,
        loadingReviews: _loadingReviews,
        reviewsError: _reviewsError,
        currentUserId: currentUserId,
        reviewUsers: _reviewUsers,
        onLoadReviews: _loadReviewsIfNeeded,
        onCreateReview: _showCreateReviewDialog,
        onEditReview: _showEditReviewDialog,
        onDeleteReview: _confirmDeleteReview,
      ),
    );
  }
}
