import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/explore_models.dart';

// ignore_for_file: prefer_initializing_formals

class ExploreService {
  final ApiClient _api;
  final AuthService _auth;

  ExploreService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  Future<ExploreListResponse> list({
    String? category,
    String? sort,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null) params['category'] = category;
    if (sort != null) params['sort'] = sort;

    final data = await _api.get(
      '/explore',
      queryParams: params,
      token: await _token(),
    );
    return ExploreListResponse.fromJson(data);
  }

  Future<ExploreListResponse> random({String? category, int limit = 20}) async {
    final params = <String, String>{'limit': limit.toString()};
    if (category != null) params['category'] = category;

    final data = await _api.get(
      '/explore/random',
      queryParams: params,
      token: await _token(),
    );
    return ExploreListResponse.fromJson(data);
  }

  Future<bool> bookmarkStatus(String id) async {
    final data = await _api.get('/explore/$id/bookmark', token: await _token());
    return data['data']['bookmarked'] as bool;
  }

  Future<void> setBookmark(String id) async {
    await _api.post('/explore/$id/bookmark', token: await _token());
  }

  Future<void> removeBookmark(String id) async {
    await _api.delete('/explore/$id/bookmark', token: await _token());
  }

  Future<ExploreListResponse> getBookmarks({
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final data = await _api.get(
      '/explore/bookmarks',
      queryParams: params,
      token: await _token(),
    );
    return ExploreListResponse.fromJson(data);
  }

  Future<ExploreListResponse> search({
    String? q,
    String? category,
    String? cuisine,
    String? sort,
    String? city,
    double? lat,
    double? lon,
    String? location,
    int radius = 5000,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'radius': radius.toString(),
    };
    if (q != null) params['q'] = q;
    if (category != null) params['category'] = category;
    if (cuisine != null) params['cuisine'] = cuisine;
    if (sort != null) params['sort'] = sort;
    if (city != null) params['city'] = city;
    if (lat != null) params['lat'] = lat.toString();
    if (lon != null) params['lon'] = lon.toString();
    if (location != null) params['location'] = location;

    final data = await _api.get(
      '/explore/search',
      queryParams: params,
      token: await _token(),
    );
    return ExploreListResponse.fromJson(data);
  }

  Future<ExplorePlace> get(String id) async {
    final data = await _api.get('/explore/$id', token: await _token());
    return ExplorePlace.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<ExplorePlace> create({
    required int osmId,
    required String osmType,
  }) async {
    final data = await _api.post(
      '/explore',
      body: CreatePlaceRequest(osmId: osmId, osmType: osmType).toJson(),
      token: await _token(),
    );
    return ExplorePlace.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<ExplorePlace> update(String id) async {
    final data = await _api.put('/explore/$id', token: await _token());
    return ExplorePlace.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('/explore/$id', token: await _token());
  }
}
