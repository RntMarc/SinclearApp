import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/dav_token_models.dart';

/// Verwaltet die DAV-Tokens des angemeldeten Nutzers
/// (Endpunkte `/user/me/dav-tokens` der API).
class DavTokenService {
  final ApiClient _api;
  final AuthService _auth;

  DavTokenService({required this._api, required this._auth});

  /// Liste aller eigenen Tokens (maximal 5 aktive Tokens pro Nutzer).
  Future<List<DavToken>> list() async {
    final data = await _api.get(
      '/user/me/dav-tokens',
      token: await _auth.getAccessToken(),
    );
    return (data['data'] as List)
        .map((e) => DavToken.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Erstellt ein neues Token mit der angegebenen Bezeichnung.
  ///
  /// Das vollständige Token wird nur einmalig in der Antwort zurückgegeben
  /// und muss vom Nutzer gespeichert werden.
  Future<DavTokenCreateResult> create(String label) async {
    final data = await _api.post(
      '/user/me/dav-tokens',
      body: {'label': label},
      token: await _auth.getAccessToken(),
    );
    return DavTokenCreateResult.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Widerruft ein Token; dieses kann danach nicht mehr verwendet werden.
  Future<void> delete(String id) async {
    await _api.delete(
      '/user/me/dav-tokens/$id',
      token: await _auth.getAccessToken(),
    );
  }
}
