import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/config/osm_config.dart';

void main() {
  setUp(() => OsmConfig.init(appId: 'de.sinclear.beyond', version: 'v1.2.3'));

  test('Web: kein User-Agent-Header (sonst CORS-Preflight, OSM blockt)', () {
    expect(OsmConfig.tileHeaders(web: true), isEmpty);
  });

  test('Nativ: App-Kennung als User-Agent für die OSM-Tile-Policy', () {
    expect(OsmConfig.tileHeaders(web: false), {
      'User-Agent': 'de.sinclear.beyond/v1.2.3',
    });
  });

  test('Standard richtet sich nach kIsWeb', () {
    expect(OsmConfig.tileHeaders().isEmpty, kIsWeb);
  });
}
