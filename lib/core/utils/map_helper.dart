import 'package:url_launcher/url_launcher.dart';
import '../../features/settings/models/map_app_preference.dart';

/// A point on the map that can be opened in an external map application.
class MapTarget {
  final double latitude;
  final double longitude;
  final int? osmId;
  final String? osmType;
  final String? label;

  const MapTarget({
    required this.latitude,
    required this.longitude,
    this.osmId,
    this.osmType,
    this.label,
  });
}

/// Builds the URL for [target] in the given [app].
String mapUrlFor(MapApp app, MapTarget target) {
  final lat = target.latitude;
  final lon = target.longitude;
  final z = 17;

  return switch (app) {
    MapApp.osm when target.osmId != null && target.osmType != null =>
      'https://www.openstreetmap.org/${target.osmType}/${target.osmId}'
      '?mlat=$lat&mlon=$lon#map=$z/$lat/$lon',
    MapApp.osm =>
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=$z/$lat/$lon',
    MapApp.googleMaps =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    MapApp.appleMaps =>
      'https://maps.apple.com/?q=$lat,$lon&ll=$lat,$lon',
    MapApp.ask =>
      '',
  };
}

/// Opens [target] in the given [app] using the device's external browser /
/// maps application. Local compatible apps (e.g. OsmAnd, Google Maps) will
/// automatically intercept matching URLs.
Future<void> openMapTarget(MapApp app, MapTarget target) async {
  if (app == MapApp.ask) return;
  final url = mapUrlFor(app, target);
  if (url.isEmpty) return;
  final uri = Uri.parse(url);
  if (uri.scheme.isNotEmpty) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
