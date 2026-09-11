import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/user_weather_location.dart';

class UserWeatherLocationService {
  final ApiClient _api;
  final AuthService _auth;

  UserWeatherLocationService({required this._api, required this._auth});

  Future<String> _token() => _auth.getAccessToken();

  Future<List<UserWeatherLocation>> list() async {
    final data = await _api.get(
      '/user/me/weather-locations',
      token: await _token(),
    );
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .map((e) => UserWeatherLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserWeatherLocation> create(UserWeatherLocation location) async {
    final data = await _api.post(
      '/user/me/weather-locations',
      body: location.toJson(),
      token: await _token(),
    );
    return UserWeatherLocation.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<UserWeatherLocation> update(
    String id,
    Map<String, dynamic> fields,
  ) async {
    final data = await _api.patch(
      '/user/me/weather-locations/$id',
      body: fields,
      token: await _token(),
    );
    return UserWeatherLocation.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete(
      '/user/me/weather-locations/$id',
      token: await _token(),
    );
  }

  Future<List<UserWeatherLocation>> replaceAll(
    List<UserWeatherLocation> locations,
  ) async {
    final data = await _api.put(
      '/user/me/weather-locations',
      body: {
        'locations': locations.map((l) => l.toJson()).toList(),
      },
      token: await _token(),
    );
    final items = data['data'] as List<dynamic>? ?? [];
    return items
        .map((e) => UserWeatherLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
