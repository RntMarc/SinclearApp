import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/osm_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/composite/design_map_marker.dart';
import '../models/explore_models.dart';

class PlaceConfirmScreen extends StatefulWidget {
  final OsmSearchResult result;

  const PlaceConfirmScreen({super.key, required this.result});

  @override
  State<PlaceConfirmScreen> createState() => _PlaceConfirmScreenState();
}

class _PlaceConfirmScreenState extends State<PlaceConfirmScreen> {
  int _step = 0;
  ExploreCategoryPreview? _categoryPreview;
  bool _loadingCategory = false;
  String? _stepError;
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _confirmLocation() {
    setState(() {
      _step = 1;
      _loadingCategory = true;
      _stepError = null;
    });
    _loadCategoryPreview();
  }

  Future<void> _loadCategoryPreview() async {
    try {
      final explore = AppScope.of(context).explore;
      final preview = await explore.previewCategory(
        osmId: widget.result.osmId,
        osmType: widget.result.osmType,
      );
      if (!mounted) return;
      setState(() {
        _categoryPreview = preview;
        _loadingCategory = false;
      });
    } catch (e, st) {
      developer.log('Failed to load category preview', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingCategory = false;
        _stepError = 'Kategorie konnte nicht geladen werden.';
      });
    }
  }

  void _confirmInfo() {
    setState(() {
      _step = 2;
      _stepError = null;
    });
  }

  Future<void> _submit() async {
    if (_rating == 0 || _commentController.text.trim().isEmpty) return;
    setState(() {
      _submitting = true;
      _stepError = null;
    });
    try {
      final explore = AppScope.of(context).explore;
      final place = await explore.create(
        osmId: widget.result.osmId,
        osmType: widget.result.osmType,
      );
      if (!mounted) return;
      await explore.createReview(
        place.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      context.go('/entdecken/${place.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _stepError = switch (e.errorCode) {
          'place_already_exists' => 'Dieser Ort existiert bereits.',
          _ => 'Fehler beim Hinzufügen.',
        };
      });
    } catch (e, st) {
      developer.log('Failed to create place', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _stepError = 'Netzwerkfehler. Bitte versuche es erneut.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
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
              title: 'Ort bestätigen',
            ),
            _buildStepper(tokens),
            Expanded(child: _buildStepContent(tokens)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(DesignTokens tokens) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg, tokens.spaceMd, tokens.spaceLg, 0,
      ),
      child: Row(
        children: [
          _stepDot(0, tokens),
          _stepLine(0, tokens),
          _stepDot(1, tokens),
          _stepLine(1, tokens),
          _stepDot(2, tokens),
        ],
      ),
    );
  }

  Widget _stepDot(int index, DesignTokens tokens) {
    final done = index < _step;
    final active = index == _step;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? tokens.primary
            : active
                ? Colors.transparent
                : tokens.border,
        border: active
            ? Border.all(color: tokens.primary, width: 2)
            : null,
      ),
      child: done
          ? Icon(Icons.check, size: 16, color: tokens.onPrimary)
          : Center(
              child: DesignText(
                '${index + 1}',
                style: DesignTextStyle.label,
                color: active ? tokens.primary : tokens.textLow,
              ),
            ),
    );
  }

  Widget _stepLine(int fromIndex, DesignTokens tokens) {
    return Expanded(
      child: Container(
        height: 2,
        color: fromIndex < _step ? tokens.primary : tokens.border,
      ),
    );
  }

  Widget _buildStepContent(DesignTokens tokens) {
    switch (_step) {
      case 0:
        return _buildMapStep(tokens);
      case 1:
        return _buildCategoryStep(tokens);
      case 2:
        return _buildRatingStep(tokens);
      default:
        return const SizedBox();
    }
  }

  Widget _buildMapStep(DesignTokens tokens) {
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        children: [
          DesignText(
            'Befindet sich der Ort an dieser Position?',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceMd),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(widget.result.lat, widget.result.lon),
                  initialZoom: 16,
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
                      designMapMarker(
                        point: LatLng(widget.result.lat, widget.result.lon),
                        icon: Icons.location_on_rounded,
                        color: tokens.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: tokens.spaceLg),
          DesignButton(
            variant: DesignButtonVariant.filled,
            label: 'Standort bestätigen',
            fullWidth: true,
            icon: Icons.check_rounded,
            onPressed: _confirmLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStep(DesignTokens tokens) {
    if (_loadingCategory) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_stepError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: tokens.danger),
              SizedBox(height: tokens.spaceSm),
              DesignText(
                _stepError!,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spaceLg),
              DesignButton(
                variant: DesignButtonVariant.filled,
                label: 'Erneut versuchen',
                onPressed: _loadCategoryPreview,
              ),
            ],
          ),
        ),
      );
    }

    final preview = _categoryPreview;
    if (preview == null) {
      return const SizedBox();
    }

    final categoryName = preview.category == 'gastronomy'
        ? 'Gastronomie'
        : 'Freizeit';

    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            'Diese Informationen werden übernommen:',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          Expanded(
            child: SingleChildScrollView(
              child: DesignCard(
                padding: EdgeInsets.all(tokens.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(Icons.store_rounded, widget.result.name, tokens),
                    _infoRow(Icons.category_rounded, categoryName, tokens),
                    if (preview.cuisine != null)
                      _infoRow(Icons.restaurant_rounded, preview.cuisine!, tokens),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: tokens.spaceLg),
          DesignButton(
            variant: DesignButtonVariant.filled,
            label: 'Informationen bestätigen',
            fullWidth: true,
            icon: Icons.check_rounded,
            onPressed: _confirmInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStep(DesignTokens tokens) {
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        children: [
          DesignText(
            'Bewerte den Ort',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceXl),
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
          SizedBox(height: tokens.spaceXl),
          DesignTextField(
            controller: _commentController,
            hint: 'Bewertungskommentar *',
            maxLines: 4,
          ),
          const Spacer(),
          if (_stepError != null)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceMd),
              child: DesignText(
                _stepError!,
                style: DesignTextStyle.body,
                color: tokens.danger,
              ),
            ),
          DesignButton(
            variant: DesignButtonVariant.filled,
            label: _submitting ? 'Wird hinzugefügt…' : 'Ort hinzufügen & bewerten',
            fullWidth: true,
            icon: Icons.add_location_alt_rounded,
            loading: _submitting,
            onPressed:
                _rating == 0 || _commentController.text.trim().isEmpty || _submitting
                    ? null
                    : _submit,
          ),
        ],
      ),
    );
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
}
