import 'package:flutter_map/flutter_map.dart';

class OsmConfig {
  OsmConfig._();

  static String _appId = 'de.example.beyond';
  static String _appVersion = 'v0.1';

  static void init({required String appId, required String version}) {
    _appId = appId;
    _appVersion = version;
  }

  static String get tileUserAgent => '$_appId/$_appVersion';
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static MapCachingProvider get tileCachingProvider =>
      BuiltInMapCachingProvider.getOrCreateInstance(
        overrideFreshAge: const Duration(days: 7),
      );
}

NetworkTileProvider osmTileProvider() => NetworkTileProvider(
  headers: {'User-Agent': OsmConfig.tileUserAgent},
  cachingProvider: OsmConfig.tileCachingProvider,
);
