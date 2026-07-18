import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/osm_config.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../user/models/user_models.dart';
import '../models/explore_models.dart';
import '../utils/cuisine_translations.dart';

class PlaceDetailWide extends StatelessWidget {
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

  const PlaceDetailWide({super.key,
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
              Expanded(flex: 3, child: PlaceInfoContent(place: place)),
              SizedBox(width: tokens.spaceXl),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    SizedBox(height: 200, child: PlaceMapCard(place: place)),
                    SizedBox(height: tokens.spaceLg),
                    PlaceActionsCard(
                      canDelete: canDelete,
                      refreshing: refreshing,
                      bookmarked: bookmarked,
                      bookmarkToggling: bookmarkToggling,
                      onRefresh: onRefresh,
                      onDelete: onDelete,
                      onToggleBookmark: onToggleBookmark,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    PlaceReviewsSection(
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

class PlaceDetailNarrow extends StatelessWidget {
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

  const PlaceDetailNarrow({super.key,
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
                      PlaceInfoContent(place: place),
                      SizedBox(height: tokens.spaceLg),
                      SizedBox(
                        height: 200,
                        child: PlaceMapCard(place: place),
                      ),
                      SizedBox(height: tokens.spaceLg),
                      PlaceActionsCard(
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
                  child: PlaceReviewsSection(
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

class PlaceInfoContent extends StatelessWidget {
  final ExplorePlace place;
  const PlaceInfoContent({super.key, required this.place});

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

class PlaceMapCard extends StatelessWidget {
  final ExplorePlace place;
  const PlaceMapCard({super.key, required this.place});

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
              interactionOptions: const InteractionOptions(
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

class PlaceActionsCard extends StatelessWidget {
  final bool canDelete;
  final bool refreshing;
  final bool bookmarked;
  final bool bookmarkToggling;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;
  final VoidCallback onToggleBookmark;

  const PlaceActionsCard({super.key,
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

class PlaceReviewsSection extends StatelessWidget {
  final List<Review>? reviews;
  final bool loading;
  final String? error;
  final String currentUserId;
  final Map<String, UserBasePublic> reviewUsers;
  final VoidCallback onLoadReviews;
  final VoidCallback onCreateReview;
  final void Function(Review) onEditReview;
  final void Function(Review) onDeleteReview;

  const PlaceReviewsSection({super.key,
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
              child: PlaceReviewCard(
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

class PlaceReviewCard extends StatelessWidget {
  final Review review;
  final bool isOwn;
  final UserBasePublic? reviewUser;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PlaceReviewCard({super.key,
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
              PlaceStarRating(rating: review.rating, size: 16),
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

class PlaceStarRating extends StatelessWidget {
  final int rating;
  final double size;

  const PlaceStarRating({super.key, required this.rating, this.size = 20});

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

class PlaceReviewForm extends StatefulWidget {
  final int? initialRating;
  final String? initialComment;

  const PlaceReviewForm({super.key, this.initialRating, this.initialComment});

  @override
  State<PlaceReviewForm> createState() => _PlaceReviewFormState();
}

class _PlaceReviewFormState extends State<PlaceReviewForm> {
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
