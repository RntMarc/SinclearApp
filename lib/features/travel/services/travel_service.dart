import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/travel_models.dart';

// ignore_for_file: prefer_initializing_formals

class TravelService {
  final ApiClient _api;
  final AuthService _auth;

  TravelService({required ApiClient api, required AuthService auth})
      : _api = api,
        _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  Future<TravelTripListResponse> list({
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final data = await _api.get(
      '/trips',
      queryParams: params,
      token: await _token(),
    );
    return TravelTripListResponse.fromJson(data);
  }
}
