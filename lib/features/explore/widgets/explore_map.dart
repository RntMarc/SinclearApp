import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/osm_config.dart';
import '../models/explore_models.dart';

class ExploreMap extends StatelessWidget {
  final List<ExplorePlace> places;
  final LatLng? center;
  final double zoom;

  const ExploreMap({
    super.key,
    required this.places,
    this.center,
    this.zoom = 13,
  });

  List<Marker> _buildMarkers() {
    return places
        .where((p) => p.latitude != null && p.longitude != null)
        .map(
          (p) => Marker(
            point: LatLng(p.latitude!, p.longitude!),
            child: Icon(
              p.category == 'gastronomy' ? Icons.restaurant : Icons.park,
              color: Colors.red,
              size: 30,
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();
    final initialCenter =
        center ??
        (markers.isNotEmpty
            ? markers.first.point
            : const LatLng(51.1657, 10.4515));

    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
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
