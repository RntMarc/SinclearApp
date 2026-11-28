import 'package:flutter/foundation.dart';
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

  /// HTTP-Header für die OSM-Tile-Requests.
  ///
  /// Im Web darf kein `User-Agent` gesetzt werden: Er ist dort ein
  /// „non-simple" Header, der einen CORS-Preflight auslöst, den
  /// `tile.openstreetmap.org` nur für `x-requested-with` erlaubt. Firefox
  /// verwirft die Kacheln dadurch komplett („CORS Missing Allow Header").
  /// Browser-UA und Referer genügen der OSM-Policy. Nativ wird kein Referer
  /// gesendet, dort ist die App-Kennung als User-Agent Pflicht.
  static Map<String, String> tileHeaders({bool? web}) => (web ?? kIsWeb)
      ? const <String, String>{}
      : <String, String>{'User-Agent': tileUserAgent};
}

NetworkTileProvider osmTileProvider() => NetworkTileProvider(
  headers: OsmConfig.tileHeaders(),
  cachingProvider: OsmConfig.tileCachingProvider,
);
