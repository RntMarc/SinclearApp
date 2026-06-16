import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/news_models.dart';

// ignore_for_file: prefer_initializing_formals

class NewsService {
  final ApiClient _api;
  final AuthService _auth;

  NewsService({required ApiClient api, required AuthService auth})
      : _api = api,
        _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  Future<NewsListResponse> list({
    String? sourceName,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (sourceName != null) params['sourceName'] = sourceName;

    final data = await _api.get(
      '/news/articles',
      queryParams: params,
      token: await _token(),
    );
    return NewsListResponse.fromJson(data);
  }

  Future<NewsListResponse> getVotes({
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final data = await _api.get(
      '/news/articles/votes',
      queryParams: params,
      token: await _token(),
    );
    return NewsListResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> vote({
    required String url,
    required String title,
    required String sourceName,
    String? sourceIcon,
  }) async {
    final body = NewsVoteRequest(
      url: url,
      title: title,
      sourceName: sourceName,
      sourceIcon: sourceIcon,
    ).toJson();
    return _api.post('/news/articles/votes', body: body, token: await _token());
  }

  Future<void> removeVote(String articleId) async {
    await _api.delete(
      '/news/articles/votes',
      body: {'articleId': articleId},
      token: await _token(),
    );
  }

  Future<NewsListResponse> getArchive({
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final data = await _api.get(
      '/news/articles/archive',
      queryParams: params,
      token: await _token(),
    );
    return NewsListResponse.fromJson(data);
  }
}
