import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/osm_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../user/models/user_models.dart';
import '../models/explore_models.dart';
import '../utils/cuisine_translations.dart';

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
      child: _ReviewForm(
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
          DesignAppBar(
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

    final isWide = MediaQuery.of(context).size.width >= 600;
    final place = _place!;
    final auth = AppScope.of(context).auth;
    final currentUserId = auth.userId ?? '';
    final isOwner = currentUserId == place.creatorId;
    final canDelete = isOwner || auth.isAdmin;

    if (isWide) {
      return _WideDetail(
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
      );
    }
    return _NarrowDetail(
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
    );
  }
}

class _WideDetail extends StatelessWidget {
  final ExplorePlace place;
  final bool canDelete;
  final bool refreshing;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;
  final VoidCallback onToggleBookmark;
  final List<Review>? reviews;
  final bool loadingReviews;
  final String? reviewsError;
  final String currentUserId;
  final Map<String, UserBasePublic> reviewUsers;
  final VoidCallback onLoadReviews;
  final VoidCallback onCreateReview;
  final void Function(Review) onEditReview;
  final void Function(Review) onDeleteReview;

  const _WideDetail({
    required this.place,
    required this.canDelete,
    required this.refreshing,
    required this.bookmarked,
    required this.bookmarkToggling,
    required this.onRefresh,
    required this.onDelete,
    required this.onToggleBookmark,
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
    final tokens = DesignTheme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: tokens.spaceSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _InfoContent(place: place)),
              SizedBox(width: tokens.spaceXl),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    SizedBox(height: 200, child: _MapCard(place: place)),
                    SizedBox(height: tokens.spaceLg),
                    _ActionsCard(
                      canDelete: canDelete,
                      refreshing: refreshing,
                      bookmarked: bookmarked,
                      bookmarkToggling: bookmarkToggling,
                      onRefresh: onRefresh,
                      onDelete: onDelete,
                      onToggleBookmark: onToggleBookmark,
                    ),
                    SizedBox(height: tokens.spaceLg),
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

class _NarrowDetail extends StatelessWidget {
  final ExplorePlace place;
  final bool canDelete;
  final bool refreshing;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;
  final VoidCallback onToggleBookmark;
  final List<Review>? reviews;
  final bool loadingReviews;
  final String? reviewsError;
  final String currentUserId;
  final Map<String, UserBasePublic> reviewUsers;
  final VoidCallback onLoadReviews;
  final VoidCallback onCreateReview;
  final void Function(Review) onEditReview;
  final void Function(Review) onDeleteReview;

  const _NarrowDetail({
    required this.place,
    required this.canDelete,
    required this.refreshing,
    required this.bookmarked,
    required this.bookmarkToggling,
    required this.onRefresh,
    required this.onDelete,
    required this.onToggleBookmark,
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
    final tokens = DesignTheme.of(context);
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
                Tab(text: 'Info'),
                Tab(text: 'Bewertungen'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.all(tokens.spaceLg),
                  child: Column(
                    children: [
                      _InfoContent(place: place),
                      SizedBox(height: tokens.spaceLg),
                      SizedBox(
                        height: 200,
                        child: _MapCard(place: place),
                      ),
                      SizedBox(height: tokens.spaceLg),
                      _ActionsCard(
                        canDelete: canDelete,
                        refreshing: refreshing,
                        bookmarked: bookmarked,
                        bookmarkToggling: bookmarkToggling,
                        onRefresh: onRefresh,
                        onDelete: onDelete,
                        onToggleBookmark: onToggleBookmark,
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.all(tokens.spaceLg),
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

class _InfoContent extends StatelessWidget {
  final ExplorePlace place;
  const _InfoContent({required this.place});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(
          place.name,
          style: DesignTextStyle.title,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceLg),
        if (place.address != null)
          _infoRow(Icons.location_on_rounded, place.address!, tokens),
        if (place.phone != null)
          _infoRow(Icons.phone_rounded, place.phone!, tokens),
        if (place.website != null)
          _infoRow(Icons.language_rounded, place.website!, tokens),
        if (place.email != null)
          _infoRow(Icons.email_rounded, place.email!, tokens),
        if (place.cuisine != null)
          _infoRow(
            Icons.restaurant_rounded,
            translateCuisine(place.cuisine),
            tokens,
          ),
        if (place.openingHours != null)
          _infoRow(Icons.schedule_rounded, place.openingHours!, tokens),
        if (place.avgRating != null)
          _infoRow(
            Icons.star_rounded,
            '${place.avgRating!.toStringAsFixed(1)} / 5',
            tokens,
          ),
        SizedBox(height: tokens.spaceLg),
        _metaRow('Kategorie', place.category == 'gastronomy' ? 'Gastronomie' : 'Freizeit', tokens),
        _metaRow('OSM-ID', '${place.osmType ?? "?"}/${place.osmId?.toString() ?? "?"}', tokens),
        _metaRow('Erstellt', place.createdAt.substring(0, 10), tokens),
        _metaRow(
          'Letzte Aktualisierung',
          place.lastUpdated.substring(0, 10),
          tokens,
        ),
      ],
    );
  }
}

Widget _infoRow(IconData icon, String text, DesignTokens tokens) {
  return Padding(
    padding: EdgeInsets.only(bottom: tokens.spaceSm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: tokens.primary),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: DesignText(
            text,
            style: DesignTextStyle.body,
            color: tokens.textHigh,
          ),
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
          width: 140,
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

class _MapCard extends StatelessWidget {
  final ExplorePlace place;
  const _MapCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    if (place.latitude == null || place.longitude == null) {
      return DesignCard(
        useGlass: false,
        child: SizedBox(
          height: 200,
          child: Center(
            child: DesignText(
              'Keine Koordinaten verfügbar',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ),
        ),
      );
    }
    return DesignCard(
      useGlass: false,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: SizedBox(
          height: 200,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(place.latitude!, place.longitude!),
              initialZoom: 15,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: OsmConfig.tileUrlTemplate,
                userAgentPackageName: OsmConfig.tileUserAgent,
                tileProvider: osmTileProvider(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(place.latitude!, place.longitude!),
                    child: Icon(
                      Icons.location_on,
                      color: tokens.danger,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final bool canDelete;
  final bool refreshing;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;
  final VoidCallback onToggleBookmark;

  const _ActionsCard({
    required this.canDelete,
    required this.refreshing,
    required this.bookmarked,
    required this.bookmarkToggling,
    required this.onRefresh,
    required this.onDelete,
    required this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          SizedBox(height: tokens.spaceSm),
          DesignButton(
            variant: DesignButtonVariant.filled,
            icon: Icons.refresh_rounded,
            label: refreshing ? 'Aktualisiere…' : 'OSM-Daten aktualisieren',
            loading: refreshing,
            onPressed: refreshing ? null : onRefresh,
          ),
          if (canDelete) ...[
            SizedBox(height: tokens.spaceSm),
            DesignButton(
              variant: DesignButtonVariant.outlined,
              icon: Icons.delete_rounded,
              label: 'Ort löschen',
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final List<Review>? reviews;
  final bool loading;
  final String? error;
  final String currentUserId;
  final Map<String, UserBasePublic> reviewUsers;
  final VoidCallback onLoadReviews;
  final VoidCallback onCreateReview;
  final void Function(Review) onEditReview;
  final void Function(Review) onDeleteReview;

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
            DesignText(error!, style: DesignTextStyle.body, color: tokens.textHigh),
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

    final items = reviews ?? <Review>[];

    return Column(
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
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
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
