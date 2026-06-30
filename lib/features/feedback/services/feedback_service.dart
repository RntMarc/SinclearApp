import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/feedback_models.dart';

// ignore_for_file: prefer_initializing_formals

class FeedbackService {
  final ApiClient _api;
  final AuthService _auth;

  FeedbackService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  Future<FeedbackSuggestionListResponse> list({
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final data = await _api.get(
      '/feedback/suggestions',
      queryParams: params,
      token: await _token(),
    );
    return FeedbackSuggestionListResponse.fromJson(data);
  }

  Future<FeedbackSuggestion> create({
    required String title,
    String? description,
  }) async {
    final body = FeedbackSuggestionCreateRequest(
      title: title,
      description: description,
    ).toJson();
    final data = await _api.post(
      '/feedback/suggestions',
      body: body,
      token: await _token(),
    );
    return FeedbackSuggestion.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> delete(String id) async {
    await _api.delete('/feedback/suggestions/$id', token: await _token());
  }

  Future<void> vote(String id) async {
    await _api.post('/feedback/suggestions/$id/vote', token: await _token());
  }

  Future<void> removeVote(String id) async {
    await _api.delete(
      '/feedback/suggestions/$id/vote',
      token: await _token(),
    );
  }

  Future<void> updateStatus(String id, FeedbackStatus status) async {
    final body = FeedbackStatusUpdateRequest(status: status).toJson();
    await _api.put(
      '/feedback/suggestions/$id/status',
      body: body,
      token: await _token(),
    );
  }
}
