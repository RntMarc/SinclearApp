// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/poll_models.dart';

/// Schlanker Wrapper um die Poll-Endpunkte der Sinclear API.
///
/// Eine Methode pro Endpunkt; Fehler werden als [ApiException] unverändert
/// durchgereicht, damit die Screens die Fehlercodes (`poll_closed`,
/// `already_voted`, `results_hidden`, …) auf deutsche Meldungen abbilden
/// können.
class PollsService {
  final ApiClient _api;
  final AuthService _auth;

  PollsService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  // --- Liste & CRUD ---

  Future<PollListResponse> list({
    PollType? type,
    PollStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (type != null) 'type': type.apiValue,
      if (status != null) 'status': status.apiValue,
    };
    final data = await _api.get(
      '/polls',
      queryParams: params,
      token: await _token(),
    );
    return PollListResponse.fromJson(data);
  }

  Future<PollDetail> create(PollCreateRequest request) async {
    final data = await _api.post(
      '/polls',
      body: request.toJson(),
      token: await _token(),
    );
    return _detail(data);
  }

  Future<PollDetail> get(String id) async {
    final data = await _api.get('/polls/$id', token: await _token());
    return _detail(data);
  }

  Future<PollDetail> update(String id, PollUpdateRequest request) async {
    final data = await _api.patch(
      '/polls/$id',
      body: request.toJson(),
      token: await _token(),
    );
    return _detail(data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/polls/$id', token: await _token());
  }

  Future<PollDetail> close(String id) async {
    final data = await _api.post('/polls/$id/close', token: await _token());
    return _detail(data);
  }

  // --- Einladungen ---

  Future<PollInviteListResponse> listInvites(String id) async {
    final data = await _api.get('/polls/$id/invites', token: await _token());
    return PollInviteListResponse.fromJson(data);
  }

  Future<PollInviteListResponse> addInvites(
    String id,
    List<String> userIds,
  ) async {
    final data = await _api.post(
      '/polls/$id/invites',
      body: {'userIds': userIds},
      token: await _token(),
    );
    return PollInviteListResponse.fromJson(data);
  }

  Future<void> removeInvite(String id, String userId) async {
    await _api.delete('/polls/$id/invites/$userId', token: await _token());
  }

  // --- Formular ---

  Future<PollResponseListResponse> listResponses(String id) async {
    final data = await _api.get('/polls/$id/responses', token: await _token());
    return PollResponseListResponse.fromJson(data);
  }

  Future<PollResponse?> submitResponse(
    String id,
    PollResponseSubmitRequest request,
  ) async {
    final data = await _api.post(
      '/polls/$id/responses',
      body: request.toJson(),
      token: await _token(),
    );
    return _response(data);
  }

  Future<PollResponse?> myResponse(String id) async {
    final data = await _api.get(
      '/polls/$id/responses/me',
      token: await _token(),
    );
    return _response(data);
  }

  Future<PollResponse?> updateResponse(
    String id,
    String responseId,
    PollResponseSubmitRequest request,
  ) async {
    final data = await _api.patch(
      '/polls/$id/responses/$responseId',
      body: request.toJson(),
      token: await _token(),
    );
    return _response(data);
  }

  // --- Terminfindung ---

  Future<PollAvailabilityListResponse> listAvailability(String id) async {
    final data = await _api.get(
      '/polls/$id/availability',
      token: await _token(),
    );
    return PollAvailabilityListResponse.fromJson(data);
  }

  Future<void> setAvailability(
    String id,
    PollAvailabilitySetRequest request,
  ) async {
    await _api.put(
      '/polls/$id/availability',
      body: request.toJson(),
      token: await _token(),
    );
  }

  Future<PollOption> addCounterProposal(
    String id,
    PollOptionInput option,
  ) async {
    final data = await _api.post(
      '/polls/$id/options',
      body: option.toJson(),
      token: await _token(),
    );
    return PollOption.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteOption(String id, String optionId) async {
    await _api.delete('/polls/$id/options/$optionId', token: await _token());
  }

  Future<PollDetail> finalize(String id, String optionId) async {
    final data = await _api.post(
      '/polls/$id/finalize',
      body: PollFinalizeRequest(optionId: optionId).toJson(),
      token: await _token(),
    );
    return _detail(data);
  }

  // --- Abstimmung ---

  Future<PollVoteStatus> voteStatus(String id) async {
    final data = await _api.get(
      '/polls/$id/vote-status',
      token: await _token(),
    );
    return PollVoteStatus.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> vote(String id, List<String> optionIds) async {
    await _api.post(
      '/polls/$id/vote',
      body: PollVoteRequest(optionIds: optionIds).toJson(),
      token: await _token(),
    );
  }

  Future<PollVoteResultResponse> results(String id) async {
    final data = await _api.get('/polls/$id/results', token: await _token());
    return PollVoteResultResponse.fromJson(data);
  }

  // --- Parser ---

  PollDetail _detail(Map<String, dynamic> data) =>
      PollDetail.fromJson(data['data'] as Map<String, dynamic>);

  PollResponse? _response(Map<String, dynamic> data) {
    final raw = data['data'];
    if (raw is! Map<String, dynamic>) return null;
    return PollResponse.fromJson(raw);
  }
}
