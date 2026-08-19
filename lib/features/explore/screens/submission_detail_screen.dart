import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/osm_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/composite/design_map_marker.dart';
import '../models/explore_models.dart';
import '../screens/submit_place_screen.dart';
import '../widgets/detail_widgets.dart';

class SubmissionDetailScreen extends StatefulWidget {
  final String id;

  const SubmissionDetailScreen({super.key, required this.id});

  @override
  State<SubmissionDetailScreen> createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends State<SubmissionDetailScreen> {
  ExploreSubmission? _submission;
  bool _loading = true;
  String? _error;
  bool _hasLoaded = false;

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
      final explore = AppScope.of(context).explore;
      final submission = await explore.getSubmission(widget.id);
      if (!mounted) return;
      setState(() {
        _submission = submission;
        _loading = false;
        _error = null;
      });
    } catch (e, st) {
      developer.log('Failed to load submission', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Einreichung konnte nicht geladen werden.';
      });
    }
  }

  Color _statusColor(DesignTokens tokens, String status) {
    return switch (status) {
      'pending' => tokens.warning,
      'approved' => tokens.success,
      'rejected' => tokens.danger,
      'transferred' => tokens.primary,
      _ => tokens.textLow,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'In Pruefung',
      'approved' => 'Freigegeben',
      'rejected' => 'Abgelehnt',
      'transferred' => 'Uebernommen',
      _ => status,
    };
  }

  Future<void> _edit() async {
    if (_submission == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitPlaceScreen(initial: _submission),
      ),
    );
    if (result == true && mounted) _load();
  }

  void _openPlace() {
    if (_submission?.targetPlaceId != null) {
      context.go('/entdecken/${_submission!.targetPlaceId}');
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
            title: 'Einreichung',
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

    if (_error != null || _submission == null) {
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

    final s = _submission!;
    final statusColor = _statusColor(tokens, s.status);

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DesignText(
                  s.name,
                  style: DesignTextStyle.title,
                  color: tokens.textHigh,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceSm,
                  vertical: tokens.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(tokens.radiusSm),
                ),
                child: DesignText(
                  _statusLabel(s.status),
                  style: DesignTextStyle.label,
                  color: statusColor,
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceLg),
          if (s.photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: Image.memory(
                base64Decode(s.photo!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: tokens.spaceLg),
          ],
          _mapCard(tokens),
          SizedBox(height: tokens.spaceLg),
          _infoSection(tokens),
          if (s.rating != null) ...[
            SizedBox(height: tokens.spaceLg),
            DesignText(
              'Deine Bewertung',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceSm),
            PlaceStarRating(rating: s.rating!, size: 28),
            if (s.comment != null && s.comment!.isNotEmpty) ...[
              SizedBox(height: tokens.spaceSm),
              DesignText(
                s.comment!,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
            ],
          ],
          if (s.adminNote != null && s.adminNote!.isNotEmpty) ...[
            SizedBox(height: tokens.spaceLg),
            DesignText(
              'Admin-Notiz',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceSm),
            Container(
              padding: EdgeInsets.all(tokens.spaceMd),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: Border.all(color: tokens.border),
              ),
              child: DesignText(
                s.adminNote!,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
            ),
          ],
          if (s.note != null && s.note!.isNotEmpty) ...[
            SizedBox(height: tokens.spaceLg),
            DesignText(
              'Deine Notiz',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              s.note!,
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          _metaSection(tokens),
          SizedBox(height: tokens.spaceXl),
          _actionButtons(tokens),
        ],
      ),
    );
  }

  Widget _mapCard(DesignTokens tokens) {
    final s = _submission!;
    final latLng = LatLng(s.latitude, s.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: latLng,
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
                designMapMarker(
                  point: latLng,
                  icon: Icons.location_on_rounded,
                  color: tokens.danger,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(DesignTokens tokens) {
    final s = _submission!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.address != null && s.address!.isNotEmpty)
          _infoRow(Icons.location_on_outlined, s.address!, tokens),
        if (s.website != null && s.website!.isNotEmpty)
          _infoRow(Icons.language_rounded, s.website!, tokens),
        if (s.mapLink != null && s.mapLink!.isNotEmpty)
          _infoRow(Icons.map_rounded, s.mapLink!, tokens),
        _infoRow(
          Icons.gps_fixed_rounded,
          '${s.latitude.toStringAsFixed(5)}, ${s.longitude.toStringAsFixed(5)}',
          tokens,
        ),
      ],
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

  Widget _metaSection(DesignTokens tokens) {
    final s = _submission!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metaRow('Erstellt', s.createdAt, tokens),
        _metaRow('Aktualisiert', s.updatedAt, tokens),
        if (s.targetPlaceId != null)
          _metaRow('Uebernommen als Place-ID', s.targetPlaceId!, tokens),
      ],
    );
  }

  Widget _metaRow(String label, String value, DesignTokens tokens) {
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceXs),
      child: Row(
        children: [
          DesignText(
            '$label: ',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          Expanded(
            child: DesignText(
              value,
              style: DesignTextStyle.label,
              color: tokens.textHigh,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(DesignTokens tokens) {
    final s = _submission!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s.isPending)
          DesignButton(
            variant: DesignButtonVariant.filled,
            icon: Icons.edit_rounded,
            label: 'Bearbeiten',
            fullWidth: true,
            onPressed: _edit,
          ),
        if (s.targetPlaceId != null) ...[
          DesignButton(
            variant: DesignButtonVariant.filled,
            icon: Icons.location_on_rounded,
            label: 'Zum Ort',
            fullWidth: true,
            onPressed: _openPlace,
          ),
          SizedBox(height: tokens.spaceSm),
        ],
      ],
    );
  }
}
