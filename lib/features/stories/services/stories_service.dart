import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/stories_models.dart';

class StoriesService {
  final ApiClient _api;
  final AuthService _auth;

  StoriesService({required this._api, required this._auth});

  Future<String> _token() => _auth.getAccessToken();

  Future<StoryFeedResponse> feed() async {
    final data = await _api.get('/stories', token: await _token());
    return StoryFeedResponse.fromJson(data);
  }

  Future<void> create({required String image, String? caption}) async {
    await _api.post(
      '/stories',
      body: StoryCreateRequest(image: image, caption: caption).toJson(),
      token: await _token(),
    );
  }

  Future<void> markViewed(String id) async {
    await _api.post('/stories/$id/view', token: await _token());
  }

  Future<void> delete(String id) async {
    await _api.delete('/stories/$id', token: await _token());
  }
}
