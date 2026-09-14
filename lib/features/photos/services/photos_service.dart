import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/photo_models.dart';

// ignore_for_file: prefer_initializing_formals

/// API-Zugriff auf den Unsplash-Foto-Feed (`GET /photos`).
///
/// Der Server filtert bereits nach Sichtbarkeit und sortiert nach Zeit
/// absteigend; der Client lädt nur seitenweise nach.
class PhotosService {
  final ApiClient _api;
  final AuthService _auth;

  PhotosService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  /// Lädt eine Seite des Foto-Feeds.
  Future<PhotoPage> feed({int page = 1, int limit = 30}) async {
    final data = await _api.get(
      '/photos',
      queryParams: {'page': '$page', 'limit': '$limit'},
      token: await _token(),
    );
    return PhotoPage.fromJson(data);
  }
}
