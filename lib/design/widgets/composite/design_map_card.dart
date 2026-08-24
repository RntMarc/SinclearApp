import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/osm_config.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_card.dart';

/// Standard composite widget for map preview and interactive map cards across the app.
class DesignMapCard extends StatelessWidget {
  final LatLng? center;
  final double initialZoom;
  final List<Marker> markers;
  final double height;
  final EdgeInsetsGeometry? margin;
  final bool interactive;
  final VoidCallback? onTap;
  final String emptyMessage;

  const DesignMapCard({
    super.key,
    this.center,
    this.initialZoom = 13.0,
    this.markers = const [],
    this.height = 200.0,
    this.margin = EdgeInsets.zero,
    this.interactive = true,
    this.onTap,
    this.emptyMessage = 'Keine Koordinaten verfügbar',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    LatLng? effectiveCenter = center;
    if (effectiveCenter == null && markers.isNotEmpty) {
      effectiveCenter = markers.first.point;
    }

    if (effectiveCenter == null) {
      return DesignCard(
        useGlass: false,
        margin: margin,
        child: SizedBox(
          height: height,
          child: Center(
            child: DesignText(
              emptyMessage,
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ),
        ),
      );
    }

    final mapWidget = FlutterMap(
      options: MapOptions(
        initialCenter: effectiveCenter,
        initialZoom: initialZoom,
        interactionOptions: InteractionOptions(
          flags: interactive
              ? (InteractiveFlag.all & ~InteractiveFlag.rotate)
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: OsmConfig.tileUrlTemplate,
          userAgentPackageName: OsmConfig.tileUserAgent,
          tileProvider: osmTileProvider(),
        ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );

    return DesignCard(
      useGlass: false,
      margin: margin,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: SizedBox(
          height: height,
        child: onTap != null
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: interactive
                    ? mapWidget
                    : AbsorbPointer(child: mapWidget),
              )
            : mapWidget,
        ),
      ),
    );
  }
}
