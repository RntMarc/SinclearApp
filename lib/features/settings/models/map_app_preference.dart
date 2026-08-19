import 'dart:async' show unawaited;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferred app for opening map coordinates / places.
enum MapApp {
  /// Show a picker each time.
  ask,

  /// OpenStreetMap website (local compatible apps intercept the link).
  osm,

  /// Google Maps.
  googleMaps,

  /// Apple Maps.
  appleMaps,
}

extension MapAppX on MapApp {
  String get label => switch (this) {
    MapApp.ask => 'Jedes Mal fragen',
    MapApp.osm => 'OpenStreetMap',
    MapApp.googleMaps => 'Google Maps',
    MapApp.appleMaps => 'Apple Maps',
  };

  String get description => switch (this) {
    MapApp.ask => 'Bei jedem Klick Auswahl zeigen',
    MapApp.osm => 'Im Browser öffnen (kompatible Apps übernehmen)',
    MapApp.googleMaps => 'Google Maps App oder Website',
    MapApp.appleMaps => 'Apple Maps (nur macOS/iOS)',
  };

  IconData get icon => switch (this) {
    MapApp.ask => Icons.touch_app_rounded,
    MapApp.osm => Icons.map_rounded,
    MapApp.googleMaps => Icons.location_on_rounded,
    MapApp.appleMaps => Icons.location_on_rounded,
  };
}

/// Local persistence of the chosen map app preference.
class MapAppPreference {
  const MapAppPreference._();

  static const _key = 'beyond.map_app';

  static Future<MapApp> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    return MapApp.values.asNameMap()[name] ?? MapApp.ask;
  }

  static Future<void> save(MapApp value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.name);
  }
}

/// A [ValueNotifier] that automatically persists every change via
/// [MapAppPreference]. Used as the single source of truth for the active
/// map app throughout the app (see [AppScope]).
class MapAppController extends ValueNotifier<MapApp> {
  MapAppController(super.value);

  @override
  set value(MapApp newValue) {
    if (newValue == value) return;
    super.value = newValue;
    unawaited(MapAppPreference.save(newValue));
  }
}
