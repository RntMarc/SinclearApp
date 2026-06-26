import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/osm_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
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
  void initState() {
    super.initState();
  }

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
        scope.explore.get(widget.id),
        scope.explore.bookmarkStatus(widget.id),
        scope.explore.getReviews(widget.id),
      ]);
      if (!mounted) return;
      final reviews = (results[2] as ReviewListResponse).data;
      await _loadReviewUsers(reviews);
      if (!mounted) return;
      setState(() {
        _place = results[0] as ExplorePlace;
        _bookmarked = results[1] as bool;
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
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('OSM-Daten aktualisiert.'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e, st) {
      developer.log('Failed to refresh place', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _refreshing = false);
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('Aktualisierung fehlgeschlagen.'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ort löschen'),
        content: Text('${_place?.name} wirklich löschen?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    try {
      final explore = AppScope.of(context).explore;
      await explore.delete(widget.id);
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('Ort gelöscht.'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      context.pop();
    } catch (e, st) {
      developer.log('Failed to delete place', error: e, stackTrace: st);
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('Löschen fehlgeschlagen.'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
            ),
          ],
        ),
      );
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
    final result = await showCupertinoDialog<({int rating, String? comment})>(
      context: context,
      builder: (_) => const _ReviewDialog(),
    );
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
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('Fehler beim Speichern.'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showEditReviewDialog(Review review) async {
    final result = await showCupertinoDialog<({int rating, String? comment})>(
      context: context,
      builder: (_) => _ReviewDialog(
        initialRating: review.rating,
        initialComment: review.comment,
      ),
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
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('Fehler beim Speichern.'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmDeleteReview(Review review) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Bewertung löschen'),
        content: const Text('Wirklich löschen?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
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
      showCupertinoDialog(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('Löschen fehlgeschlagen.'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null || _place == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 8),
            Text(_error ?? 'Unbekannter Fehler'),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.back, size: 18),
                Text('Zurück'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _InfoContent(place: place)),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _MapCard(place: place),
                    const SizedBox(height: 16),
                    _ActionsCard(
                      canDelete: canDelete,
                      refreshing: refreshing,
                      bookmarked: bookmarked,
                      bookmarkToggling: bookmarkToggling,
                      onRefresh: onRefresh,
                      onDelete: onDelete,
                      onToggleBookmark: onToggleBookmark,
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

class _NarrowDetail extends StatefulWidget {
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
  State<_NarrowDetail> createState() => _NarrowDetailState();
}

class _NarrowDetailState extends State<_NarrowDetail> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Icon(CupertinoIcons.back),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CupertinoSegmentedControl<int>(
                  children: const {
                    0: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Info'),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Bewertungen'),
                    ),
                  },
                  onValueChanged: (value) =>
                      setState(() => _selectedTab = value),
                  groupValue: _selectedTab,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        Expanded(
          child: _selectedTab == 0
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoContent(place: widget.place),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _MapCard(place: widget.place),
                      ),
                      const SizedBox(height: 16),
                      _ActionsCard(
                        canDelete: widget.canDelete,
                        refreshing: widget.refreshing,
                        bookmarked: widget.bookmarked,
                        bookmarkToggling: widget.bookmarkToggling,
                        onRefresh: widget.onRefresh,
                        onDelete: widget.onDelete,
                        onToggleBookmark: widget.onToggleBookmark,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _ReviewsSection(
                    reviews: widget.reviews,
                    loading: widget.loadingReviews,
                    error: widget.reviewsError,
                    currentUserId: widget.currentUserId,
                    reviewUsers: widget.reviewUsers,
                    onLoadReviews: widget.onLoadReviews,
                    onCreateReview: widget.onCreateReview,
                    onEditReview: widget.onEditReview,
                    onDeleteReview: widget.onDeleteReview,
                  ),
                ),
        ),
      ],
    );
  }
}

class _InfoContent extends StatelessWidget {
  final ExplorePlace place;
  const _InfoContent({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place.name,
          style: theme.textTheme.textStyle.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (place.address != null)
          _InfoRow(CupertinoIcons.location_solid, place.address!),
        if (place.phone != null)
          _InfoRow(CupertinoIcons.phone, place.phone!),
        if (place.website != null)
          _InfoRow(CupertinoIcons.globe, place.website!),
        if (place.email != null)
          _InfoRow(CupertinoIcons.envelope, place.email!),
        if (place.cuisine != null)
          _InfoRow(
            CupertinoIcons.book,
            translateCuisine(place.cuisine),
          ),
        if (place.openingHours != null)
          _InfoRow(CupertinoIcons.clock, place.openingHours!),
        if (place.avgRating != null)
          _InfoRow(
            CupertinoIcons.star_fill,
            '${place.avgRating!.toStringAsFixed(1)} / 5',
          ),
        const SizedBox(height: 16),
        _MetaRow(
          'Kategorie',
          place.category == 'gastronomy' ? 'Gastronomie' : 'Freizeit',
        ),
        _MetaRow('OSM-ID', '${place.osmType ?? "?"}/${place.osmId ?? "?"}'),
        _MetaRow('Erstellt', place.createdAt.substring(0, 10)),
        _MetaRow('Letzte Aktualisierung', place.lastUpdated.substring(0, 10)),
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
    final theme = CupertinoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.textStyle)),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.textStyle.copyWith(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.textStyle.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final ExplorePlace place;
  const _MapCard({required this.place});

  @override
  Widget build(BuildContext context) {
    if (place.latitude == null || place.longitude == null) {
      return Container(
        decoration: _cardDecoration(context),
        child: const SizedBox(
          height: 200,
          child: Center(child: Text('Keine Koordinaten verfügbar')),
        ),
      );
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardDecoration(context),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(place.latitude!, place.longitude!),
            initialZoom: 15,
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
                  child: const Icon(
                    CupertinoIcons.location_solid,
                    color: CupertinoColors.systemRed,
                    size: 36,
                  ),
                ),
              ],
            ),
            SimpleAttributionWidget(
              source: const Text('OpenStreetMap contributors'),
              onTap: () =>
                  launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            ),
          ],
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
    return Container(
      decoration: _cardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoButton(
            color: CupertinoTheme.of(context)
                .primaryColor
                .withValues(alpha: 0.12),
            onPressed: bookmarkToggling ? null : onToggleBookmark,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (bookmarkToggling)
                  const CupertinoActivityIndicator(radius: 8)
                else
                  Icon(
                    bookmarked
                        ? CupertinoIcons.bookmark_fill
                        : CupertinoIcons.bookmark,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                Text(
                  bookmarkToggling
                      ? '…'
                      : bookmarked
                          ? 'Lesezeichen entfernen'
                          : 'Lesezeichen setzen',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            color: CupertinoTheme.of(context)
                .primaryColor
                .withValues(alpha: 0.12),
            onPressed: refreshing ? null : onRefresh,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (refreshing)
                  const CupertinoActivityIndicator(radius: 8)
                else
                  const Icon(CupertinoIcons.refresh, size: 18),
                const SizedBox(width: 8),
                Text(
                  refreshing ? 'Aktualisiere…' : 'OSM-Daten aktualisieren',
                ),
              ],
            ),
          ),
          if (canDelete) ...[
            const SizedBox(height: 8),
            CupertinoButton(
              color: CupertinoColors.systemRed.resolveFrom(context),
              onPressed: onDelete,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.trash, size: 18),
                  SizedBox(width: 8),
                  Text('Ort löschen'),
                ],
              ),
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
    if (loading && reviews == null) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (error != null && reviews == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 8),
            Text(error!),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: onLoadReviews,
              child: const Text('Erneut versuchen'),
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
            Text(
              'Bewertungen',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            CupertinoButton(
              color: CupertinoTheme.of(context)
                  .primaryColor
                  .withValues(alpha: 0.12),
              onPressed: onCreateReview,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.plus, size: 18),
                  SizedBox(width: 4),
                  Text('Schreiben'),
                ],
              ),
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
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
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
    final theme = CupertinoTheme.of(context);
    return Container(
      decoration: _cardDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reviewUser != null) ...[
            GestureDetector(
              onTap: () => context.go('/kontakte/${review.userId}'),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipOval(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          image: resolveImageProvider(reviewUser!.image) !=
                                  null
                              ? DecorationImage(
                                  image: resolveImageProvider(
                                      reviewUser!.image)!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: resolveImageProvider(reviewUser!.image) == null
                            ? Center(
                                child: Text(
                                  reviewUser!.displayName.isNotEmpty
                                      ? reviewUser!.displayName[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      reviewUser!.displayName,
                      style: theme.textTheme.textStyle.copyWith(
                        fontSize: 14,
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
                CupertinoButton(
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(28, 28),
                  onPressed: onEdit,
                  child: const Icon(CupertinoIcons.pencil, size: 18),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(28, 28),
                  onPressed: onDelete,
                  child: Icon(
                    CupertinoIcons.trash,
                    size: 18,
                    color: CupertinoColors.systemRed.resolveFrom(context),
                  ),
                ),
              ],
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment!, style: theme.textTheme.textStyle),
          ],
          const SizedBox(height: 4),
          Text(
            _formatDate(review.createdAt),
            style: theme.textTheme.textStyle.copyWith(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
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
    final color = CupertinoTheme.of(context).primaryColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
          size: size,
          color: color,
        ),
      ),
    );
  }
}

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
    return CupertinoAlertDialog(
      title: Text(isEditing ? 'Bewertung bearbeiten' : 'Bewertung schreiben'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _rating;
              return CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onPressed: () => setState(() => _rating = i + 1),
                child: Icon(
                  filled ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  color: filled
                      ? CupertinoTheme.of(context).primaryColor
                      : CupertinoColors.secondaryLabel.resolveFrom(context),
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _commentController,
            placeholder: 'Kommentar (optional)',
            maxLines: 3,
            decoration: BoxDecoration(
              border: Border.all(
                color: CupertinoColors.systemGrey4.resolveFrom(context),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
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

BoxDecoration _cardDecoration(BuildContext context) {
  return BoxDecoration(
    color: CupertinoColors.systemBackground.resolveFrom(context),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: CupertinoColors.systemGrey4.resolveFrom(context).withValues(alpha: 0.5),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
