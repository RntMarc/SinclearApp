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
  final NominatimResult result;

  const PlaceConfirmScreen({super.key, required this.result});

  @override
  State<PlaceConfirmScreen> createState() => _PlaceConfirmScreenState();
}

class _PlaceConfirmScreenState extends State<PlaceConfirmScreen> {
  int _step = 0;
  Map<String, dynamic>? _osmDetail;
  String? _stepError;
  bool _loadingOsm = false;
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

  Future<void> _confirmLocation() async {
    setState(() {
      _step = 1;
      _loadingOsm = true;
      _stepError = null;
    });
    try {
      final nominatim = AppScope.of(context).nominatim;
      final detail = await nominatim.lookup(
        widget.result.osmId,
        widget.result.osmType,
      );
      if (!mounted) return;
      setState(() {
        _osmDetail = detail;
        _loadingOsm = false;
        if (detail == null) _stepError = 'Details konnten nicht geladen werden.';
      });
    } catch (e, st) {
      developer.log('Failed to load OSM details', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingOsm = false;
        _stepError = 'OSM-Details konnten nicht geladen werden.';
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
        return _buildInfoStep(tokens);
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

  Widget _buildInfoStep(DesignTokens tokens) {
    if (_loadingOsm) {
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
                onPressed: _confirmLocation,
              ),
            ],
          ),
        ),
      );
    }

    if (_osmDetail == null) {
      return const SizedBox();
    }

    final detail = _osmDetail!;
    final name = _extractName(detail);
    final address = _formatAddress(detail);
    final extratags = detail['extratags'] as Map<String, dynamic>? ?? {};
    final phone = extratags['phone'] as String?;
    final website = extratags['website'] as String?;
    final email = extratags['contact:email'] as String? ?? extratags['email'] as String?;
    final openingHours = extratags['opening_hours'] as String?;
    final categoryType = detail['type'] as String? ?? detail['category'] as String? ?? '';

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
                    _infoRow(Icons.store_rounded, name, tokens),
                    if (address != null)
                      _infoRow(Icons.location_on_rounded, address, tokens),
                    if (categoryType.isNotEmpty)
                      _infoRow(Icons.category_rounded, categoryType, tokens),
                    if (phone != null)
                      _infoRow(Icons.phone_rounded, phone, tokens),
                    if (website != null)
                      _infoRow(Icons.language_rounded, website, tokens),
                    if (email != null)
                      _infoRow(Icons.email_rounded, email, tokens),
                    if (openingHours != null)
                      _infoRow(Icons.schedule_rounded, openingHours, tokens),
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

  String _extractName(Map<String, dynamic> detail) {
    final displayName = detail['display_name'] as String? ?? '';
    final first = displayName.split(',').first.trim();
    return first.isNotEmpty ? first : 'Unbekannter Ort';
  }

  String? _formatAddress(Map<String, dynamic> detail) {
    final address = detail['address'] as Map<String, dynamic>?;
    if (address == null || address.isEmpty) return null;
    final parts = <String>[];
    for (final key in [
      'house_number', 'road', 'city', 'state', 'postcode', 'country',
    ]) {
      final val = address[key] as String?;
      if (val != null && val.isNotEmpty) {
        if (key == 'postcode' && parts.isNotEmpty) {
          parts[parts.length - 1] = '${parts.last} $val';
        } else {
          parts.add(val);
        }
      }
    }
    return parts.isEmpty ? null : parts.join(', ');
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
