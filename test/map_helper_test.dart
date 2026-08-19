import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/settings/models/map_app_preference.dart';
import 'package:sinclear_beyond/core/utils/map_helper.dart';

void main() {
  group('mapUrlFor', () {
    const target = MapTarget(
      latitude: 48.1351,
      longitude: 11.582,
      osmId: 123456,
      osmType: 'node',
    );

    test('OpenStreetMap with osmType and osmId', () {
      final url = mapUrlFor(MapApp.osm, target);
      expect(
        url,
        'https://www.openstreetmap.org/node/123456'
        '?mlat=48.1351&mlon=11.582#map=17/48.1351/11.582',
      );
    });

    test('OpenStreetMap without osmType falls back to coordinates', () {
      const noType = MapTarget(latitude: 48.1351, longitude: 11.582);
      final url = mapUrlFor(MapApp.osm, noType);
      expect(
        url,
        'https://www.openstreetmap.org/'
        '?mlat=48.1351&mlon=11.582#map=17/48.1351/11.582',
      );
    });

    test('OpenStreetMap with osmId but no osmType falls back to coordinates', () {
      const idOnly = MapTarget(
        latitude: 48.1351,
        longitude: 11.582,
        osmId: 123456,
      );
      final url = mapUrlFor(MapApp.osm, idOnly);
      expect(
        url,
        'https://www.openstreetmap.org/'
        '?mlat=48.1351&mlon=11.582#map=17/48.1351/11.582',
      );
    });

    test('Google Maps uses query API', () {
      final url = mapUrlFor(MapApp.googleMaps, target);
      expect(
        url,
        'https://www.google.com/maps/search/?api=1&query=48.1351,11.582',
      );
    });

    test('Apple Maps uses ll and q parameters', () {
      final url = mapUrlFor(MapApp.appleMaps, target);
      expect(
        url,
        'https://maps.apple.com/?q=48.1351,11.582&ll=48.1351,11.582',
      );
    });

    test('ask returns empty string', () {
      final url = mapUrlFor(MapApp.ask, target);
      expect(url, '');
    });
  });
}
