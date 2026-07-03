import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/location_sharing_models.dart';

// ignore_for_file: prefer_initializing_formals

class LocationSharingService {
  final ApiClient _api;
  final AuthService _auth;

  LocationSharingService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  Future<LocationSharingSessionDetail> createSession(
    CreateSessionRequest req,
  ) async {
    final data = await _api.post(
      '/location-sharing/sessions',
      body: req.toJson(),
      token: await _token(),
    );
    return LocationSharingSessionDetail.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<LocationSharingSession>> getMySessions() async {
    final data = await _api.get(
      '/location-sharing/sessions',
      token: await _token(),
    );
    return (data['data'] as List<dynamic>)
        .map((e) =>
            LocationSharingSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LocationSharingSessionDetail> getSessionDetail(String id) async {
    final data = await _api.get(
      '/location-sharing/sessions/$id',
      token: await _token(),
    );
    return LocationSharingSessionDetail.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }

  Future<LocationSharingSessionDetail> updateSession(
    String id,
    UpdateSessionRequest req,
  ) async {
    final data = await _api.patch(
      '/location-sharing/sessions/$id',
      body: req.toJson(),
      token: await _token(),
    );
    return LocationSharingSessionDetail.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> endSession(String id) async {
    await _api.delete(
      '/location-sharing/sessions/$id',
      token: await _token(),
    );
  }

  Future<String> sendLocation(
    String sessionId,
    SendLocationRequest req,
  ) async {
    final data = await _api.post(
      '/location-sharing/sessions/$sessionId/locations',
      body: req.toJson(),
      token: await _token(),
    );
    return (data['data'] as Map<String, dynamic>)['id'] as String;
  }

  Future<List<LocationSharingLocation>> getLocations(
    String sessionId, {
    DateTime? since,
  }) async {
    final params = <String, String>{};
    if (since != null) {
      params['since'] = since.toUtc().toIso8601String();
    }
    final data = await _api.get(
      '/location-sharing/sessions/$sessionId/locations',
      queryParams: params.isNotEmpty ? params : null,
      token: await _token(),
    );
    return (data['data'] as List<dynamic>)
        .map((e) =>
            LocationSharingLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LocationSharingActiveSession>> getActiveFromContacts() async {
    final data = await _api.get(
      '/location-sharing/active',
      token: await _token(),
    );
    return (data['data'] as List<dynamic>)
        .map((e) =>
            LocationSharingActiveSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
