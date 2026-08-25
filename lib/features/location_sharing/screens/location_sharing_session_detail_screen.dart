import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/osm_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_map_marker.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/location_sharing_models.dart';

/// Zeigt die aktuelle Position einer geteilten Standort-Session eines
/// Kontakts.
class LocationSharingSessionDetailScreen extends StatefulWidget {
  final String sessionId;

  /// Anzeigename des Teilenden (aus der Listen-Ansicht mitgegeben), damit der
  /// Header sofort ohne weiteren Request steht.
  final String? ownerName;

  const LocationSharingSessionDetailScreen({
    super.key,
    required this.sessionId,
    this.ownerName,
  });

  @override
  State<LocationSharingSessionDetailScreen> createState() =>
      _LocationSharingSessionDetailScreenState();
}

class _LocationSharingSessionDetailScreenState
    extends State<LocationSharingSessionDetailScreen> {
  static const _pollInterval = Duration(seconds: 30);

  List<LocationSharingLocation> _locations = const [];
  bool _loading = true;
  String? _error;
  bool _didLoad = false;
  Timer? _timer;
  DateTime? _since;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoad) {
      _didLoad = true;
      _load();
      _timer = Timer.periodic(_pollInterval, (_) => _load());
    }
  }

  Future<void> _load() async {
    try {
      final scope = AppScope.of(context);
      final locations = await scope.locationSharing.getLocations(
        widget.sessionId,
        since: _since,
      );
      if (!mounted) return;
      setState(() {
        if (locations.isNotEmpty) {
          final existing = _locations.where(
            (l) => !locations.any((n) => n.id == l.id),
          );
          _locations = [...existing, ...locations]
            ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
          _since = _locations
              .map((l) => l.recordedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
        }
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_locations.isEmpty) {
          _error = 'Standort konnte nicht geladen werden.';
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.ownerName ?? 'Standort';

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: title,
            actions: [
              DesignIconButton(icon: Icons.refresh_rounded, onPressed: _load),
            ],
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: tokens.danger),
            const SizedBox(height: 8),
            DesignText(_error!),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: DesignText(
            _summary(),
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ),
        Expanded(child: _map(tokens)),
      ],
    );
  }

  String _summary() {
    final last = _locations.isEmpty ? null : _locations.last;
    if (last == null) return 'Noch kein Standort';
    final time = formatDateTime(last.recordedAt);
    final acc = last.accuracy != null ? ' · ±${last.accuracy!.round()} m' : '';
    return 'Zuletzt aktualisiert: $time$acc';
  }

  Widget _map(DesignTokens tokens) {
    if (_locations.isEmpty) {
      return Center(
        child: DesignText(
          'Noch kein Standort',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }

    final last = _locations.last;
    final center = LatLng(last.latitude, last.longitude);
    final accuracy = last.accuracy;

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
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
        if (accuracy != null && accuracy > 0)
          CircleLayer(
            circles: [
              CircleMarker(
                point: center,
                radius: accuracy,
                useRadiusInMeter: true,
                color: tokens.primary.withValues(alpha: 0.15),
                borderStrokeWidth: 1.5,
                borderColor: tokens.primary.withValues(alpha: 0.4),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            designMapMarker(
              point: center,
              icon: Icons.location_on_rounded,
              color: tokens.primary,
              size: 28,
            ),
          ],
        ),
      ],
    );
  }
}
