import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/image/image_compressor.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_map_card.dart';
import '../../../design/widgets/composite/design_map_marker.dart';
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

  /// Gast-Modus: Bewertungen werden ausgeblendet.
  final bool guest;
  final List<Review>? reviews;
  final bool loadingReviews;
  final String? reviewsError;
  final String currentUserId;
  final Map<String, UserBasePublic> reviewUsers;
  final VoidCallback onLoadReviews;
  final VoidCallback onCreateReview;
  final void Function(Review) onEditReview;
  final void Function(Review) onDeleteReview;
  final void Function(Review) onReportReview;

  const PlaceDetailWide({
    super.key,
    required this.place,
    this.guest = false,
    required this.reviews,
    required this.loadingReviews,
    this.reviewsError,
    required this.currentUserId,
    required this.reviewUsers,
    required this.onLoadReviews,
    required this.onCreateReview,
    required this.onEditReview,
    required this.onDeleteReview,
    required this.onReportReview,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    PlaceReviewsSection(
                      reviews: reviews,
                      loading: loadingReviews,
                      error: reviewsError,
                      currentUserId: currentUserId,
                      reviewUsers: reviewUsers,
                      guest: guest,
                      onLoadReviews: onLoadReviews,
                      onCreateReview: onCreateReview,
                      onEditReview: onEditReview,
                      onDeleteReview: onDeleteReview,
                      onReportReview: onReportReview,
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

  /// Gast-Modus: Bewertungen werden ausgeblendet.
  final bool guest;
  final List<Review>? reviews;
  final bool loadingReviews;
  final String? reviewsError;
  final String currentUserId;
  final Map<String, UserBasePublic> reviewUsers;
  final VoidCallback onLoadReviews;
  final VoidCallback onCreateReview;
  final void Function(Review) onEditReview;
  final void Function(Review) onDeleteReview;
  final void Function(Review) onReportReview;

  const PlaceDetailNarrow({
    super.key,
    required this.place,
    this.guest = false,
    required this.reviews,
    required this.loadingReviews,
    this.reviewsError,
    required this.currentUserId,
    required this.reviewUsers,
    required this.onLoadReviews,
    required this.onCreateReview,
    required this.onEditReview,
    required this.onDeleteReview,
    required this.onReportReview,
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
                      SizedBox(height: 200, child: PlaceMapCard(place: place)),
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
                    guest: guest,
                    onLoadReviews: onLoadReviews,
                    onCreateReview: onCreateReview,
                    onEditReview: onEditReview,
                    onDeleteReview: onDeleteReview,
                    onReportReview: onReportReview,
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
        _metaRow(
          'Kategorie',
          place.category == 'gastronomy' ? 'Gastronomie' : 'Freizeit',
          tokens,
        ),
        _metaRow(
          'OSM-ID',
          '${place.osmType ?? "?"}/${place.osmId?.toString() ?? "?"}',
          tokens,
        ),
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
        DesignText(value, style: DesignTextStyle.label, color: tokens.textHigh),
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
    final hasCoords = place.latitude != null && place.longitude != null;
    return DesignMapCard(
      center: hasCoords ? LatLng(place.latitude!, place.longitude!) : null,
      initialZoom: 15,
      markers: hasCoords
          ? [
              designMapMarker(
                point: LatLng(place.latitude!, place.longitude!),
                icon: Icons.location_on_rounded,
                color: tokens.danger,
              ),
            ]
          : const [],
      height: 200,
      interactive: true,
    );
  }
}

class PlaceReviewsSection extends StatelessWidget {
  final List<Review>? reviews;
  final bool loading;
  final String? error;
  final String currentUserId;
  final Map<String, UserBasePublic> reviewUsers;

  /// Gast-Modus: statt Bewertungen wird ein Login-Hinweis angezeigt.
  final bool guest;
  final VoidCallback onLoadReviews;
  final VoidCallback onCreateReview;
  final void Function(Review) onEditReview;
  final void Function(Review) onDeleteReview;
  final void Function(Review) onReportReview;

  const PlaceReviewsSection({
    super.key,
    required this.reviews,
    required this.loading,
    this.error,
    required this.currentUserId,
    required this.reviewUsers,
    this.guest = false,
    required this.onLoadReviews,
    required this.onCreateReview,
    required this.onEditReview,
    required this.onDeleteReview,
    required this.onReportReview,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (guest) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: tokens.textLow),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              'Bewertungen sind nur für angemeldete Nutzer sichtbar.',
              style: DesignTextStyle.body,
              color: tokens.textHigh,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceLg),
            DesignButton(
              variant: DesignButtonVariant.filled,
              icon: Icons.login_rounded,
              label: 'Zum Login',
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      );
    }

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
                onReport: () => onReportReview(review),
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
  final VoidCallback onReport;

  const PlaceReviewCard({
    super.key,
    required this.review,
    required this.isOwn,
    this.reviewUser,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
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
              DesignIconButton(icon: Icons.flag_rounded, onPressed: onReport),
              if (isOwn) ...[
                DesignIconButton(icon: Icons.edit_rounded, onPressed: onEdit),
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
          if (review.photo != null) ...[
            SizedBox(height: tokens.spaceSm),
            _ReviewPhoto(photo: review.photo!),
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

/// Zeigt das Base64-Foto einer Bewertung; bei ungültigen Daten nichts.
class _ReviewPhoto extends StatelessWidget {
  final String photo;

  const _ReviewPhoto({required this.photo});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Image.memory(
          base64Decode(photo),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
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
  Uint8List? _photoBytes;
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final rawBytes = await picked.readAsBytes();
    final compressed = compressImage(rawBytes);
    if (compressed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bild konnte nicht verarbeitet werden.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _photoBytes = compressed);
  }

  void _showImagePicker() {
    final tokens = DesignTheme.of(context);
    showDesignSheet<bool>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesignText(
              'Foto hinzufügen',
              style: DesignTextStyle.title,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceLg),
            DesignButton(
              variant: DesignButtonVariant.outlined,
              icon: Icons.camera_alt_rounded,
              label: 'Kamera',
              fullWidth: true,
              onPressed: () => Navigator.pop(context, true),
            ),
            SizedBox(height: tokens.spaceSm),
            DesignButton(
              variant: DesignButtonVariant.outlined,
              icon: Icons.photo_library_rounded,
              label: 'Galerie',
              fullWidth: true,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    ).then((useCamera) {
      if (useCamera == null || !mounted) return;
      _pickImage(useCamera ? ImageSource.camera : ImageSource.gallery);
    });
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
          SizedBox(height: tokens.spaceMd),
          if (_photoBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: Stack(
                children: [
                  Image.memory(
                    _photoBytes!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: DesignIconButton(
                      icon: Icons.close_rounded,
                      onPressed: () => setState(() => _photoBytes = null),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: tokens.spaceSm),
          ],
          DesignButton(
            variant: DesignButtonVariant.outlined,
            icon: Icons.add_a_photo_outlined,
            label: _photoBytes == null ? 'Foto hinzufügen' : 'Foto ändern',
            fullWidth: true,
            onPressed: _showImagePicker,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Max. 200 KB, JPEG/PNG/WebP. Das Foto kann nur innerhalb von '
            '24 Stunden nach dem Erstellen der Bewertung hinzugefügt werden.',
            style: DesignTextStyle.label,
            color: tokens.textLow,
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
                    photo: _photoBytes,
                  )),
          ),
        ],
      ),
    );
  }
}
