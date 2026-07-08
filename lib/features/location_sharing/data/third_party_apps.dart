import 'package:flutter/material.dart';

/// Metadata for all supported third-party location tracking apps.
///
/// The [key] matches the API route key used in integration URLs.
/// [websiteUrl] is a placeholder — replace with real download page URLs.
class ThirdPartyApp {
  final String key;
  final String name;
  final String description;
  final IconData icon;
  final String websiteUrl;
  final bool recommended;

  const ThirdPartyApp({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.websiteUrl,
    this.recommended = false,
  });
}

const List<ThirdPartyApp> allThirdPartyApps = [
  ThirdPartyApp(
    key: 'osmand',
    name: 'OsmAnd',
    description: 'Offline-Karten mit integriertem GPS-Tracking und Live-Teilen.',
    icon: Icons.map_rounded,
    websiteUrl: '', // TODO: https://osmand.net/ einfügen
    recommended: true,
  ),
  ThirdPartyApp(
    key: 'gpslogger',
    name: 'GPSLogger',
    description: 'Leichtgewichtiges Tracking mit flexiblen Export- und Server-Optionen.',
    icon: Icons.gps_fixed_rounded,
    websiteUrl: '', // TODO: https://gpslogger.app/ einfügen
  ),
  ThirdPartyApp(
    key: 'owntracks',
    name: 'Owntracks',
    description: 'Open-Source GPS-Tracker mit MQTT/HTTP-Unterstützung.',
    icon: Icons.location_on_rounded,
    websiteUrl: '', // TODO: https://owntracks.org/ einfügen
  ),
  ThirdPartyApp(
    key: 'ulogger',
    name: 'uLogger',
    description: 'Einfacher GPS-Logger mit Track-Aufzeichnung und Server-Upload.',
    icon: Icons.navigation_rounded,
    websiteUrl: '', // TODO: Link einfügen
  ),
  ThirdPartyApp(
    key: 'traccar',
    name: 'Traccar',
    description: 'Umfassendes GPS-Tracking-System mit Web-Oberfläche und App.',
    icon: Icons.cell_tower_rounded,
    websiteUrl: '', // TODO: https://www.traccar.org/ einfügen
  ),
  ThirdPartyApp(
    key: 'opengts',
    name: 'OpenGTS',
    description: 'Open-Source-Fleet-Tracking mit benutzerdefinierten Servern.',
    icon: Icons.route_rounded,
    websiteUrl: '', // TODO: https://opengts.org/ einfügen
  ),
  ThirdPartyApp(
    key: 'overland',
    name: 'Overland',
    description: 'Passives GPS-Tracking für iOS mit GeoJSON-Export.',
    icon: Icons.hiking_rounded,
    websiteUrl: '', // TODO: https://overland.p3k.app/ einfügen
  ),
  ThirdPartyApp(
    key: 'locusmap',
    name: 'Locus Map',
    description: 'Outdoor-Navigation mit GPS-Logging und Server-Synchronisation.',
    icon: Icons.terrain_rounded,
    websiteUrl: '', // TODO: https://www.locusmap.app/ einfügen
  ),
  ThirdPartyApp(
    key: 'httpGet',
    name: 'HTTP GET',
    description: 'Generischer Endpunkt — passt zu jeder App, die URL-Parameter sendet.',
    icon: Icons.api_rounded,
    websiteUrl: '',
  ),
  ThirdPartyApp(
    key: 'httpPost',
    name: 'HTTP POST',
    description: 'Generischer Endpunkt — passt zu jeder App, die JSON-Daten sendet.',
    icon: Icons.http_rounded,
    websiteUrl: '',
  ),
];
