import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/weather_constants.dart';
import '../models/weather_models.dart';

const _kStorageKey = 'saved_weather_locations';

class WeatherPreferences {
  final SharedPreferences _prefs;

  WeatherPreferences(this._prefs);

  static Future<WeatherPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return WeatherPreferences(prefs);
  }

  List<SavedLocation> load() {
    final raw = _prefs.getString(_kStorageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavedLocation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<SavedLocation> locations) async {
    final encoded = jsonEncode(locations.map((l) => l.toJson()).toList());
    await _prefs.setString(_kStorageKey, encoded);
  }

  Future<bool> addLocation(SavedLocation location) async {
    final current = load();
    if (current.length >= kMaxSavedWeatherLocations) return false;
    current.add(location);
    await save(current);
    return true;
  }

  Future<void> removeLocation(int index) async {
    final current = load();
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    await save(current);
  }
}
