import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/osm_config.dart';
import '../../../design/theme/design_theme.dart';
import '../models/explore_models.dart';

class ExploreMap extends StatefulWidget {
  final List<ExplorePlace> places;
  final LatLng? center;
  final double zoom;

  const ExploreMap({
    super.key,
    required this.places,
    this.center,
    this.zoom = 13,
  });

  @override
  State<ExploreMap> createState() => _ExploreMapState();
}

class _ExploreMapState extends State<ExploreMap> {
  List<Marker>? _cachedMarkers;

  @override
  void initState() {
    super.initState();
    _cachedMarkers = [];
  }

  @override
  void didUpdateWidget(ExploreMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places) {
      _cachedMarkers = null;
    }
  }

  List<Marker> _buildMarkers(List<ExplorePlace> places) {
    final color = DesignTheme.of(context).danger;
    return places
        .where((p) => p.latitude != null && p.longitude != null)
        .map(
          (p) => Marker(
            point: LatLng(p.latitude!, p.longitude!),
            child: Icon(
              p.category == 'gastronomy' ? Icons.restaurant : Icons.park,
              color: color,
              size: 30,
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final markers =
        _cachedMarkers ??= _buildMarkers(widget.places);
    final initialCenter =
        widget.center ??
        (markers.isNotEmpty
            ? markers.first.point
            : const LatLng(51.1657, 10.4515));

    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: widget.zoom,
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
        MarkerLayer(markers: markers),
      ],
    );
  }
}
