import '../models/weather_models.dart';
import '../constants/weather_constants.dart';
import 'user_weather_location_service.dart';
import '../models/user_weather_location.dart';

class SyncedWeatherPreferences {
  final UserWeatherLocationService _service;
  List<SavedLocation> _locations = [];

  SyncedWeatherPreferences(this._service);

  List<SavedLocation> get locations => List.unmodifiable(_locations);

  Future<void> init() async {
    _locations = await _fetchFromServer();
  }

  Future<List<SavedLocation>> _fetchFromServer() async {
    try {
      final remote = await _service.list();
      return remote.map((uwl) => SavedLocation(
        name: uwl.name,
        slug: uwl.slug,
        lat: uwl.lat,
        lon: uwl.lon,
        source: uwl.source,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addLocation(SavedLocation location) async {
    if (_locations.length >= kMaxSavedWeatherLocations) return false;
    try {
      final created = await _service.create(UserWeatherLocation(
        id: '',
        name: location.name,
        slug: location.slug,
        lat: location.lat,
        lon: location.lon,
        source: location.source,
        createdAt: '',
        updatedAt: '',
      ));
      _locations.add(SavedLocation(
        name: created.name,
        slug: created.slug,
        lat: created.lat,
        lon: created.lon,
        source: created.source,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> removeLocation(int index) async {
    if (index < 0 || index >= _locations.length) return;
    try {
      final remote = await _service.list();
      if (index < remote.length) {
        await _service.delete(remote[index].id);
      }
      _locations.removeAt(index);
    } catch (_) {
      // Optimistic removal even if server call fails
      _locations.removeAt(index);
    }
  }

  Future<void> save(List<SavedLocation> locations) async {
    try {
      final remoteLocations = locations.map((l) => UserWeatherLocation(
        id: '',
        name: l.name,
        slug: l.slug,
        lat: l.lat,
        lon: l.lon,
        source: l.source,
        createdAt: '',
        updatedAt: '',
      )).toList();
      final result = await _service.replaceAll(remoteLocations);
      _locations = result.map((uwl) => SavedLocation(
        name: uwl.name,
        slug: uwl.slug,
        lat: uwl.lat,
        lon: uwl.lon,
        source: uwl.source,
      )).toList();
    } catch (_) {
      _locations = locations;
    }
  }
}
