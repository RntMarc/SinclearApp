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

  Future<TravelTripListResponse> list({int page = 1, int limit = 20}) async {
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

  Future<TravelTrip> getTrip(String id) async {
    final data = await _api.get('/trips/$id', token: await _token());
    return TravelTrip.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TravelEventListResponse> getEvents(String tripId) async {
    final data = await _api.get('/trips/$tripId/events', token: await _token());
    return TravelEventListResponse.fromJson(data);
  }

  Future<TravelAccommodationListResponse> getAccommodations(
    String tripId,
  ) async {
    final data = await _api.get(
      '/trips/$tripId/accommodations',
      token: await _token(),
    );
    return TravelAccommodationListResponse.fromJson(data);
  }

  Future<TravelParticipantListResponse> getParticipants(String tripId) async {
    final data = await _api.get(
      '/trips/$tripId/participants',
      token: await _token(),
    );
    return TravelParticipantListResponse.fromJson(data);
  }

  Future<TravelStandaloneEventListResponse> getStandaloneEvents({
    int page = 1,
    int limit = 100,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final data = await _api.get(
      '/trips/standaloneevents',
      queryParams: params,
      token: await _token(),
    );
    return TravelStandaloneEventListResponse.fromJson(data);
  }
}
