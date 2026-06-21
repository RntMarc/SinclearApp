import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';

class OsmConfig {
  OsmConfig._();

  static String get _appId => dotenv.env['APP_ID'] ?? 'de.example.beyond';
  static String get _appVersion => dotenv.env['APP_VERSION'] ?? 'v0.1';

  static String get tileUserAgent => '$_appId/$_appVersion';
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static MapCachingProvider get tileCachingProvider =>
      BuiltInMapCachingProvider.getOrCreateInstance(
        overrideFreshAge: Duration(days: 7),
      );
}

NetworkTileProvider osmTileProvider() => NetworkTileProvider(
  headers: {'User-Agent': OsmConfig.tileUserAgent},
  cachingProvider: OsmConfig.tileCachingProvider,
);
