import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/moderation_models.dart';

// ignore_for_file: prefer_initializing_formals

class ModerationService {
  final ApiClient _api;
  final AuthService _auth;

  ModerationService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  /// Erstellt eine neue Meldung oder Anfrage.
  ///
  /// Die API liefert bei 201 Created ein teilweise befülltes Objekt zurück,
  /// das nicht alle Felder enthält (z. B. fehlen status/createdAt/updatedAt).
  /// Da das Ergebnis aktuell nicht genutzt wird, wird der Body nicht geparst.
  Future<void> create({
    required ModerationRequestType requestType,
    required ModerationObjectType objectType,
    required String objectId,
    required String message,
  }) async {
    final body = ModerationRequestCreateRequest(
      requestType: requestType,
      objectType: objectType,
      objectId: objectId,
      message: message,
    ).toJson();
    await _api.post('/moderation-requests', body: body, token: await _token());
  }

  /// Eigene Anfragen inklusive Status und Admin-Kommentar.
  Future<ModerationRequestListResponse> listMine({
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final data = await _api.get(
      '/moderation-requests/mine',
      queryParams: params,
      token: await _token(),
    );
    return ModerationRequestListResponse.fromJson(data);
  }
}
