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

  Future<FeedbackCommentListResponse> listComments(String suggestionId) async {
    final data = await _api.get(
      '/feedback/suggestions/$suggestionId/comments',
      token: await _token(),
    );
    return FeedbackCommentListResponse.fromJson(data);
  }

  Future<FeedbackComment> createComment(
    String suggestionId, {
    required String text,
    String? parentId,
  }) async {
    final body = FeedbackCommentCreateRequest(
      text: text,
      parentId: parentId,
    ).toJson();
    final data = await _api.post(
      '/feedback/suggestions/$suggestionId/comments',
      body: body,
      token: await _token(),
    );
    return FeedbackComment.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<FeedbackComment> updateComment(
    String suggestionId,
    String commentId, {
    required String text,
  }) async {
    final body = FeedbackCommentUpdateRequest(text: text).toJson();
    final data = await _api.put(
      '/feedback/suggestions/$suggestionId/comments/$commentId',
      body: body,
      token: await _token(),
    );
    return FeedbackComment.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteComment(String suggestionId, String commentId) async {
    await _api.delete(
      '/feedback/suggestions/$suggestionId/comments/$commentId',
      token: await _token(),
    );
  }

  Future<BugReportResponse> submitBugReport({
    required String text,
    String? version,
    int? buildNumber,
    String? image,
  }) async {
    final body = BugReportRequest(
      text: text,
      version: version,
      buildNumber: buildNumber,
      image: image,
    ).toJson();
    final data = await _api.post(
      '/feedback/bug-report',
      body: body,
      token: await _token(),
    );
    return BugReportResponse.fromJson(data);
  }
}
