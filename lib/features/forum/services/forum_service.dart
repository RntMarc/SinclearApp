import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/forum_models.dart';

// ignore_for_file: prefer_initializing_formals

class ForumService {
  final ApiClient _api;
  final AuthService _auth;

  ForumService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  // --- Forums ---

  Future<ForumListResponse> list({int page = 1, int limit = 20}) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final data = await _api.get(
      '/forums',
      queryParams: params,
      token: await _token(),
    );
    return ForumListResponse.fromJson(data);
  }

  Future<ForumDetail> get(String id) async {
    final data = await _api.get('/forums/$id', token: await _token());
    return ForumDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  // --- Members ---

  Future<void> join(String id) async {
    await _api.post('/forums/$id/members', token: await _token());
  }

  Future<void> leave(String id) async {
    await _api.delete('/forums/$id/members', token: await _token());
  }

  Future<ForumMemberListResponse> listMembers(String id) async {
    final data = await _api.get('/forums/$id/members', token: await _token());
    return ForumMemberListResponse.fromJson(data);
  }

  Future<void> setNotifications(String id, {required bool enabled}) async {
    await _api.put(
      '/forums/$id/members/notifications',
      body: {'notificationsEnabled': enabled},
      token: await _token(),
    );
  }

  // --- Posts ---

  Future<FeedPostListResponse> listPosts(
    String forumId, {
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final data = await _api.get(
      '/forums/$forumId/posts',
      queryParams: params,
      token: await _token(),
    );
    return FeedPostListResponse.fromJson(data);
  }

  Future<FeedPost> createPost(
    String forumId, {
    String? type,
    required Map<String, dynamic> content,
  }) async {
    final body = FeedPostCreateRequest(type: type, content: content).toJson();
    final data = await _api.post(
      '/forums/$forumId/posts',
      body: body,
      token: await _token(),
    );
    return FeedPost.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deletePost(String forumId, String postId) async {
    await _api.delete('/forums/$forumId/posts/$postId', token: await _token());
  }

  Future<void> votePost(String forumId, String postId) async {
    await _api.post(
      '/forums/$forumId/posts/$postId/vote',
      token: await _token(),
    );
  }

  Future<void> removeVotePost(String forumId, String postId) async {
    await _api.delete(
      '/forums/$forumId/posts/$postId/vote',
      token: await _token(),
    );
  }

  // --- Comments ---

  Future<FeedPostCommentListResponse> listComments(
    String forumId,
    String postId,
  ) async {
    final data = await _api.get(
      '/forums/$forumId/posts/$postId/comments',
      token: await _token(),
    );
    return FeedPostCommentListResponse.fromJson(data);
  }

  Future<FeedPostComment> createComment(
    String forumId,
    String postId, {
    required String text,
    String? parentId,
  }) async {
    final body = <String, dynamic>{'text': text};
    if (parentId != null) body['parentId'] = parentId;
    final data = await _api.post(
      '/forums/$forumId/posts/$postId/comments',
      body: body,
      token: await _token(),
    );
    return FeedPostComment.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteComment(
    String forumId,
    String postId,
    String commentId,
  ) async {
    await _api.delete(
      '/forums/$forumId/posts/$postId/comments/$commentId',
      token: await _token(),
    );
  }
}
