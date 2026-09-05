import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/weather_models.dart';

class WeatherService {
  final ApiClient _api;
  final AuthService _auth;

  WeatherService({required this._api, required this._auth});

  Future<String> _token() => _auth.getAccessToken();

  /// Fetches weather data for a location.
  ///
  /// Provide [citySlug] for InfraNode-supported German cities, or [lat] and
  /// [lon] for Open-Meteo global fallback. Both can be provided to let the
  /// API merge sources.
  Future<WeatherResponse> getWeather({
    String? citySlug,
    double? lat,
    double? lon,
  }) async {
    final params = <String, String>{};
    if (citySlug != null && citySlug.isNotEmpty) {
      params['city_slug'] = citySlug;
    }
    if (lat != null && lon != null) {
      params['lat'] = lat.toString();
      params['lon'] = lon.toString();
    }

    final data = await _api.get(
      '/external-data/weather',
      queryParams: params,
      token: await _token(),
    );
    return WeatherResponse.fromJson(data);
  }

  /// Searches for locations by [query] string.
  Future<List<LocationSearchResult>> searchLocations(String query) async {
    final data = await _api.get(
      '/external-data/locations/search',
      queryParams: {'q': query},
      token: await _token(),
    );
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .map((e) => LocationSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
