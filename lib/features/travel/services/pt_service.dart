import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/pt_models.dart';

class PublicTransportService {
  final ApiClient _api;
  final AuthService _auth;

  PublicTransportService({required this._api, required this._auth});

  Future<String> _token() => _auth.getAccessToken();

  Future<List<PtStation>> searchStations(
    String query, {
    int limit = 10,
  }) async {
    final data = await _api.get(
      '/public-transport/stations',
      queryParams: {'q': query, 'limit': limit.toString()},
      token: await _token(),
    );
    return PtStationListResponse.fromJson(data).data;
  }

  Future<PtJourneySearchResponse> findJourneys({
    required String from,
    required String to,
    String? departure,
    bool arriveBy = false,
    int results = 5,
    int? maxTransfers,
    String? pageCursor,
  }) async {
    final params = <String, String>{
      'from': from,
      'to': to,
      'results': results.toString(),
      'departure': ?departure,
      if (arriveBy) 'arriveBy': 'true',
      if (maxTransfers != null) 'maxTransfers': maxTransfers.toString(),
      'pageCursor': ?pageCursor,
    };

    final data = await _api.get(
      '/public-transport/journeys',
      queryParams: params,
      token: await _token(),
    );
    return PtJourneySearchResponse.fromJson(data);
  }

  Future<PtSavedJourney> saveJourney(PtSaveJourneyRequest request) async {
    final data = await _api.post(
      '/public-transport/journeys',
      body: request.toJson(),
      token: await _token(),
    );
    return PtSavedJourney.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PtSavedJourneyListResponse> listJourneys({
    String? tripId,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'tripId': ?tripId,
    };

    final data = await _api.get(
      '/public-transport/journeys/list',
      queryParams: params,
      token: await _token(),
    );
    return PtSavedJourneyListResponse.fromJson(data);
  }

  Future<PtSavedJourney> getJourney(String id) async {
    final data = await _api.get(
      '/public-transport/journeys/$id',
      token: await _token(),
    );
    return PtSavedJourney.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteJourney(String id) async {
    await _api.delete(
      '/public-transport/journeys/$id',
      token: await _token(),
      parseResponse: false,
    );
  }

  Future<PtSavedJourney> refreshJourney(String id) async {
    final data = await _api.post(
      '/public-transport/journeys/$id/refresh',
      token: await _token(),
    );
    return PtSavedJourney.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> addParticipant(String journeyId, String userId) async {
    await _api.post(
      '/public-transport/journeys/$journeyId/participants',
      body: {'userId': userId},
      token: await _token(),
    );
  }

  Future<void> removeParticipant(
    String journeyId,
    String userId,
  ) async {
    await _api.delete(
      '/public-transport/journeys/$journeyId/participants/$userId',
      token: await _token(),
      parseResponse: false,
    );
  }

  // TODO: Replace with actual PATCH call once
  //       PATCH /public-transport/journeys/{id} is available in the API.
  //       See doc/pt_plan.md section 2.
  Future<PtSavedJourney> updateJourneyTripId(
    String journeyId,
    String? tripId,
  ) async {
    throw UnimplementedError(
      'PATCH /public-transport/journeys/$journeyId not yet available in API. '
      'See doc/pt_plan.md section 2.',
    );
  }
}
