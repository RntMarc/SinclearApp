import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ort löschen'),
        content: Text('${_place?.name} wirklich löschen?'),
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
    final result = await showDialog<({int rating, String? comment})>(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern.')));
    }
  }

  Future<void> _showEditReviewDialog(Review review) async {
    final result = await showDialog<({int rating, String? comment})>(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern.')));
    }
  }

  Future<void> _confirmDeleteReview(Review review) async {
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _place == null) {
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
          const BackButton(),
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
                    Tab(text: 'Info'),
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
                      _InfoContent(place: place),
                      const SizedBox(height: 16),
                      SizedBox(height: 200, child: _MapCard(place: place)),
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

class _InfoContent extends StatelessWidget {
  final ExplorePlace place;
  const _InfoContent({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(place.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (place.address != null)
          _InfoRow(Icons.location_on_rounded, place.address!),
        if (place.phone != null) _InfoRow(Icons.phone_rounded, place.phone!),
        if (place.website != null)
          _InfoRow(Icons.language_rounded, place.website!),
        if (place.email != null) _InfoRow(Icons.email_rounded, place.email!),
        if (place.cuisine != null)
          _InfoRow(Icons.restaurant_rounded, translateCuisine(place.cuisine)),
        if (place.openingHours != null)
          _InfoRow(Icons.schedule_rounded, place.openingHours!),
        if (place.avgRating != null)
          _InfoRow(Icons.star_rounded, '${place.avgRating!.toStringAsFixed(1)} / 5'),
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

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value, style: theme.textTheme.bodySmall),
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
      return const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: Text('Keine Koordinaten verfügbar')),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
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
                    Icons.location_on,
                    color: Colors.red,
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
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: refreshing ? null : onRefresh,
              icon: refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(
                refreshing ? 'Aktualisiere…' : 'OSM-Daten aktualisieren',
              ),
            ),
            if (canDelete) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Ort löschen'),
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

    final items = reviews ?? <Review>[];

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
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: resolveImageProvider(reviewUser!.image),
                        child: resolveImageProvider(reviewUser!.image) == null
                            ? Text(
                                reviewUser!.displayName.isNotEmpty
                                    ? reviewUser!.displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
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
      final dt = DateTime.parse(iso);
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
    final theme = Theme.of(context);
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
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
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
