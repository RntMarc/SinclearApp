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

/// Zeigt den Standort-Verlauf (bzw. die aktuelle Position) einer geteilten
/// Session eines Kontakts.
class LocationSharingSessionDetailScreen extends StatefulWidget {
  final String sessionId;

  /// Optional aus der Listen-Ansicht mitgegebene Besitzer-/Modus-Information,
  /// damit der Header sofort ohne weiteren Request steht.
  final ActiveLocationSharing? active;

  const LocationSharingSessionDetailScreen({
    super.key,
    required this.sessionId,
    this.active,
  });

  @override
  State<LocationSharingSessionDetailScreen> createState() =>
      _LocationSharingSessionDetailScreenState();
}

class _LocationSharingSessionDetailScreenState
    extends State<LocationSharingSessionDetailScreen> {
  static const _pollInterval = Duration(seconds: 30);

  List<LocationSharingLocation> _locations = const [];
  SharingMode _mode = SharingMode.location;
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
      _mode = widget.active?.session.sharingMode ?? SharingMode.location;
      _load();
      _timer = Timer.periodic(_pollInterval, (_) => _load());
    }
  }

  Future<void> _load() async {
    try {
      final scope = AppScope.of(context);
      if (widget.active == null) {
        final session = await scope.locationSharing.getSession(
          widget.sessionId,
        );
        if (mounted) _mode = session.sharingMode;
      }
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
    final title = widget.active?.ownerDisplayName ?? 'Standort';

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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DesignText(
              _summary(),
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ),
          _map(tokens),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _summary() {
    final last = _locations.isEmpty ? null : _locations.last;
    final count = _locations.length;
    final modeLabel = _mode.label;
    if (last == null) return '$modeLabel · Noch keine Punkte';
    return '$modeLabel · $count ${count == 1 ? 'Punkt' : 'Punkte'} · '
        'Letzter ${formatDateTime(last.recordedAt)}';
  }

  Widget _map(DesignTokens tokens) {
    if (_locations.isEmpty) {
      return SizedBox(
        height: 260,
        child: Center(
          child: DesignText(
            'Noch keine Standortpunkte',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
        ),
      );
    }

    final points = _locations
        .map((l) => LatLng(l.latitude, l.longitude))
        .toList();
    final center = points.last;

    final polylines = _mode == SharingMode.route && points.length >= 2
        ? [Polyline(points: points, color: tokens.primary, strokeWidth: 4)]
        : <Polyline>[];

    final markers = points
        .map(
          (p) => designMapMarker(
            point: p,
            icon: Icons.location_on_rounded,
            color: tokens.primary,
            size: 28,
          ),
        )
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        boxShadow: tokens.surfaceShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: SizedBox(
          height: 260,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
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
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),
        ),
      ),
    );
  }
}
