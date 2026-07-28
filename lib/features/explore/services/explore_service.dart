import 'package:flutter/foundation.dart';
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
    const typeMap = {'node': 'N', 'way': 'W', 'relation': 'R'};
    final apiType = typeMap[osmType] ?? osmType;
    final data = await _api.post(
      '/explore',
      body: CreatePlaceRequest(osmId: osmId, osmType: apiType).toJson(),
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

  Future<ReviewListResponse> getReviews(
    String placeId, {
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final data = await _api.get(
      '/explore/$placeId/reviews',
      queryParams: params,
      token: await _token(),
    );
    return ReviewListResponse.fromJson(data);
  }

  Future<Review> createReview(
    String placeId, {
    required int rating,
    String? comment,
  }) async {
    final body = CreateReviewRequest(rating: rating, comment: comment).toJson();
    final data = await _api.post(
      '/explore/$placeId/reviews',
      body: body,
      token: await _token(),
    );
    return Review.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Review> updateReview(
    String placeId,
    String reviewId, {
    int? rating,
    String? comment,
  }) async {
    final body = UpdateReviewRequest(rating: rating, comment: comment).toJson();
    final data = await _api.put(
      '/explore/$placeId/reviews/$reviewId',
      body: body,
      token: await _token(),
    );
    return Review.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteReview(String placeId, String reviewId) async {
    await _api.delete(
      '/explore/$placeId/reviews/$reviewId',
      token: await _token(),
    );
  }

  Future<ExploreSubmission> createSubmission(
    ExploreSubmissionCreateRequest request,
  ) async {
    debugPrint('[explore_service] createSubmission: calling _api.post');
    final data = await _api.post(
      '/explore/submissions',
      body: request.toJson(),
      token: await _token(),
    );
    debugPrint(
      '[explore_service] createSubmission: _api.post returned, keys=${data.keys}',
    );
    debugPrint(
      '[explore_service] createSubmission: data["data"] type=${data['data'].runtimeType}',
    );
    final submissionData = data['data'] as Map<String, dynamic>;
    debugPrint(
      '[explore_service] createSubmission: parsing ExploreSubmission, keys=${submissionData.keys}',
    );
    final result = ExploreSubmission.fromJson(submissionData);
    debugPrint(
      '[explore_service] createSubmission: parsed OK, id=${result.id}',
    );
    return result;
  }

  Future<ExploreSubmissionListResponse> getSubmissions({
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final data = await _api.get(
      '/explore/submissions',
      queryParams: params,
      token: await _token(),
    );
    return ExploreSubmissionListResponse.fromJson(data);
  }

  Future<ExploreSubmission> getSubmission(String id) async {
    final data = await _api.get(
      '/explore/submissions/$id',
      token: await _token(),
    );
    return ExploreSubmission.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<ExploreSubmission> updateSubmission(
    String id,
    ExploreSubmissionUpdateRequest request,
  ) async {
    debugPrint('[explore_service] updateSubmission: calling _api.put id=$id');
    final data = await _api.put(
      '/explore/submissions/$id',
      body: request.toJson(),
      token: await _token(),
    );
    debugPrint(
      '[explore_service] updateSubmission: _api.put returned, keys=${data.keys}',
    );
    return ExploreSubmission.fromJson(data['data'] as Map<String, dynamic>);
  }
}
