import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../moderation/models/moderation_models.dart';
import '../../moderation/widgets/moderation_request_sheet.dart';
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

/// Aktionen im Header-Menü des Ortes.
enum _PlaceMenuAction { refresh, delete, requestDeletion, report }

class _DetailScreenState extends State<DetailScreen> {
  ExplorePlace? _place;
  bool _loading = true;
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
      if (!scope.auth.isLoggedIn) {
        final place = await scope.explore.get(widget.id);
        if (!mounted) return;
        setState(() {
          _place = place;
          _loading = false;
          _error = null;
        });
        return;
      }
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
    try {
      final explore = AppScope.of(context).explore;
      final place = await explore.update(widget.id);
      if (!mounted) return;
      setState(() => _place = place);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OSM-Daten aktualisiert.')));
    } catch (e, st) {
      developer.log('Failed to refresh place', error: e, stackTrace: st);
      if (!mounted) return;
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
    } on ApiException catch (e) {
      developer.log('Failed to delete place', error: e);
      if (!mounted) return;
      if (e.errorCode == 'edit_window_expired') {
        await _requestDeletion();
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Löschen fehlgeschlagen.')));
    } catch (e, st) {
      developer.log('Failed to delete place', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Löschen fehlgeschlagen.')));
    }
  }

  Future<void> _requestDeletion() async {
    await showModerationRequestSheet(
      context,
      objectType: ModerationObjectType.explorePlace,
      objectId: widget.id,
      objectName: _place?.name ?? 'Ort',
      isOwn: true,
    );
  }

  Future<void> _report() async {
    final place = _place;
    if (place == null) return;
    await showModerationRequestSheet(
      context,
      objectType: ModerationObjectType.explorePlace,
      objectId: place.id,
      objectName: place.name,
      isOwn: false,
    );
  }

  Future<void> _reportReview(Review review) async {
    await showModerationRequestSheet(
      context,
      objectType: ModerationObjectType.exploreComment,
      objectId: review.id,
      objectName: 'Bewertung zu ${_place?.name ?? 'Ort'}',
      isOwn: false,
    );
  }

  bool get _isOwner {
    final place = _place;
    if (place == null) return false;
    final userId = AppScope.of(context).auth.userId;
    return userId != null && userId == place.creatorId;
  }

  /// Löschen wie ein normaler Ersteller: nur ohne Bewertungen und innerhalb
  /// des 30-Minuten-Fensters (die API erzwingt beides serverseitig).
  bool get _canDeleteAsOwner {
    final place = _place;
    if (place == null || !_isOwner) return false;
    if ((_reviews ?? const []).isNotEmpty) return false;
    // ponytail: Client-Uhr schätzt das 30-Minuten-Fenster; die API erzwingt
    // es serverseitig, bei Drift greift der edit_window_expired-Fallback.
    return canDeleteWithinWindow(place.createdAt);
  }

  Widget _buildMenuButton() {
    final tokens = DesignTheme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: PopupMenuButton<_PlaceMenuAction>(
        onSelected: _onMenuSelected,
        offset: const Offset(0, 44),
        color: tokens.surface,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: tokens.surfaceVariant,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
          child: Icon(
            Icons.more_vert_rounded,
            size: 20,
            color: tokens.textHigh,
          ),
        ),
        itemBuilder: (context) {
          final admin = AppScope.of(context).auth.isAdmin;
          final adminDelete = admin && !_canDeleteAsOwner;
          return [
            const PopupMenuItem(
              value: _PlaceMenuAction.refresh,
              child: _PlaceMenuEntry(
                icon: Icons.refresh_rounded,
                label: 'OSM-Daten aktualisieren',
              ),
            ),
            if (adminDelete)
              const PopupMenuItem(
                value: _PlaceMenuAction.delete,
                child: _PlaceMenuEntry(
                  icon: Icons.delete_rounded,
                  label: '👑 Ort löschen',
                  danger: true,
                ),
              ),
            PopupMenuItem(
              value: _canDeleteAsOwner
                  ? _PlaceMenuAction.delete
                  : _isOwner
                  ? _PlaceMenuAction.requestDeletion
                  : _PlaceMenuAction.report,
              child: _PlaceMenuEntry(
                icon: _canDeleteAsOwner
                    ? Icons.delete_rounded
                    : Icons.flag_rounded,
                label: _canDeleteAsOwner
                    ? 'Ort löschen'
                    : _isOwner
                    ? 'Löschung beantragen'
                    : 'Ort melden',
                danger: _canDeleteAsOwner,
              ),
            ),
          ];
        },
      ),
    );
  }

  void _onMenuSelected(_PlaceMenuAction action) {
    switch (action) {
      case _PlaceMenuAction.refresh:
        _refresh();
      case _PlaceMenuAction.delete:
        _delete();
      case _PlaceMenuAction.requestDeletion:
        _requestDeletion();
      case _PlaceMenuAction.report:
        _report();
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
    final result = await _showReviewSheet(
      initialRating: null,
      initialComment: null,
    );
    if (result == null || !mounted) return;
    try {
      final review = await AppScope.of(context).explore.createReview(
        widget.id,
        rating: result.rating,
        comment: result.comment,
      );
      await _uploadReviewPhotoIfPicked(review.id, result.photo);
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
      final updated = await AppScope.of(context).explore.updateReview(
        widget.id,
        review.id,
        rating: result.rating,
        comment: result.comment,
      );
      await _uploadReviewPhotoIfPicked(updated.id, result.photo);
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

  /// Lädt ein in der Bewertungsform gewähltes Foto zur Bewertung hoch.
  ///
  /// Fehler werden nur gemeldet, wenn das Foto-Fenster (24 h) oder die
  /// Berechtigung das Hochladen verweigern; Bewertung selbst bleibt gespeichert.
  Future<void> _uploadReviewPhotoIfPicked(
    String reviewId,
    Uint8List? photo,
  ) async {
    if (photo == null || !mounted) return;
    try {
      await AppScope.of(
        context,
      ).explore.setReviewPhoto(widget.id, reviewId, photo: base64Encode(photo));
    } catch (e, st) {
      developer.log('Failed to upload review photo', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException
                ? 'Bewertung gespeichert, aber das Foto konnte nicht '
                      'hochgeladen werden.'
                : 'Bewertung gespeichert, Foto-Fehler: $e',
          ),
        ),
      );
    }
  }

  Future<({int rating, String? comment, Uint8List? photo})?> _showReviewSheet({
    int? initialRating,
    String? initialComment,
  }) {
    return showDesignSheet<({int rating, String? comment, Uint8List? photo})>(
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
    final guest = !AppScope.of(context).auth.isLoggedIn;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesignSurface(
        child: Column(
          children: [
            DesignSubpageHeader(
              leading: DesignIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
              ),
              title: _place?.name ?? 'Details',
              actions: [
                if (!guest) ...[
                  DesignIconButton(
                    icon: _bookmarked == true
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    onPressed: _bookmarkToggling ? null : _toggleBookmark,
                  ),
                  if (_place != null) _buildMenuButton(),
                ],
              ],
            ),
            Expanded(child: _buildBody(tokens, guest)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(DesignTokens tokens, bool guest) {
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

    if (isWide) {
      return RefreshIndicator(
        onRefresh: _load,
        child: PlaceDetailWide(
          place: place,
          guest: guest,
          reviews: _reviews,
          loadingReviews: _loadingReviews,
          reviewsError: _reviewsError,
          currentUserId: currentUserId,
          reviewUsers: _reviewUsers,
          onLoadReviews: _loadReviewsIfNeeded,
          onCreateReview: _showCreateReviewDialog,
          onEditReview: _showEditReviewDialog,
          onDeleteReview: _confirmDeleteReview,
          onReportReview: _reportReview,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: PlaceDetailNarrow(
        place: place,
        guest: guest,
        reviews: _reviews,
        loadingReviews: _loadingReviews,
        reviewsError: _reviewsError,
        currentUserId: currentUserId,
        reviewUsers: _reviewUsers,
        onLoadReviews: _loadReviewsIfNeeded,
        onCreateReview: _showCreateReviewDialog,
        onEditReview: _showEditReviewDialog,
        onDeleteReview: _confirmDeleteReview,
        onReportReview: _reportReview,
      ),
    );
  }
}

/// Zeile im Header-Menü: Icon + Label im Design-Styling.
class _PlaceMenuEntry extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;

  const _PlaceMenuEntry({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: danger ? tokens.danger : tokens.primary),
        const SizedBox(width: 12),
        DesignText(label, style: DesignTextStyle.body),
      ],
    );
  }
}
