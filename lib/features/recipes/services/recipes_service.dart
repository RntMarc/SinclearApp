import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/recipes_models.dart';

class RecipesService {
  final ApiClient _api;
  final AuthService _auth;

  RecipesService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  Future<RecipeListResponse> list({
    String? search,
    String? sort,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sort != null) params['sort'] = sort;

    final data = await _api.get(
      '/recipes',
      queryParams: params,
      token: await _token(),
    );
    return RecipeListResponse.fromJson(data);
  }

  Future<RecipeDetail> get(String id) async {
    final data = await _api.get('/recipes/$id', token: await _token());
    return RecipeDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<RecipeDetail> create(RecipeCreateRequest request) async {
    final data = await _api.post(
      '/recipes',
      body: request.toJson(),
      token: await _token(),
    );
    return RecipeDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> update(String id, RecipeUpdateRequest request) async {
    await _api.patch(
      '/recipes/$id',
      body: request.toJson(),
      token: await _token(),
    );
  }

  Future<void> delete(String id) async {
    await _api.delete('/recipes/$id', token: await _token());
  }

  Future<bool> bookmarkStatus(String id) async {
    final data = await _api.get(
      '/recipes/$id/bookmark',
      token: await _token(),
    );
    return (data['data'] as Map<String, dynamic>)['bookmarked'] as bool;
  }

  Future<void> setBookmark(String id) async {
    await _api.post('/recipes/$id/bookmark', token: await _token());
  }

  Future<void> removeBookmark(String id) async {
    await _api.delete('/recipes/$id/bookmark', token: await _token());
  }

  Future<RecipeBookmarkListResponse> getBookmarks({
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final data = await _api.get(
      '/recipes/bookmarks',
      queryParams: params,
      token: await _token(),
    );
    return RecipeBookmarkListResponse.fromJson(data);
  }

  Future<RecipeReviewListResponse> getReviews(
    String recipeId, {
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final data = await _api.get(
      '/recipes/$recipeId/reviews',
      queryParams: params,
      token: await _token(),
    );
    return RecipeReviewListResponse.fromJson(data);
  }

  Future<RecipeReview> createReview(
    String recipeId, {
    required int rating,
    String? comment,
  }) async {
    final body = RecipeReviewCreateRequest(
      rating: rating,
      comment: comment,
    ).toJson();
    final data = await _api.post(
      '/recipes/$recipeId/reviews',
      body: body,
      token: await _token(),
    );
    return RecipeReview.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<RecipeReview> updateReview(
    String recipeId,
    String reviewId, {
    int? rating,
    String? comment,
  }) async {
    final body = RecipeReviewUpdateRequest(
      rating: rating,
      comment: comment,
    ).toJson();
    final data = await _api.patch(
      '/recipes/$recipeId/reviews/$reviewId',
      body: body,
      token: await _token(),
    );
    return RecipeReview.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteReview(String recipeId, String reviewId) async {
    await _api.delete(
      '/recipes/$recipeId/reviews/$reviewId',
      token: await _token(),
    );
  }
}
