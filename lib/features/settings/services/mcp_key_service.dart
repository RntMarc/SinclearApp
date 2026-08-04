import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/mcp_key_models.dart';

/// Verwaltet die MCP-API-Keys des angemeldeten Nutzers
/// (Endpunkte `/mcp/keys` der API).
class McpKeyService {
  final ApiClient _api;
  final AuthService _auth;

  McpKeyService({required this._api, required this._auth});

  /// Liste aller eigenen API-Keys (maximal 3 aktive Keys pro Nutzer).
  Future<List<McpApiKey>> list() async {
    final data = await _api.get(
      '/mcp/keys',
      token: await _auth.getAccessToken(),
    );
    return (data['data'] as List)
        .map((e) => McpApiKey.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Erstellt einen neuen API-Key mit der angegebenen Bezeichnung.
  ///
  /// Der vollständige Key wird nur einmalig in der Antwort zurückgegeben
  /// und muss vom Nutzer gespeichert werden.
  Future<McpApiKeyCreateResult> create(String label) async {
    final data = await _api.post(
      '/mcp/keys',
      body: {'label': label},
      token: await _auth.getAccessToken(),
    );
    return McpApiKeyCreateResult.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Löscht einen API-Key; dieser kann danach nicht mehr verwendet werden.
  Future<void> delete(String id) async {
    await _api.delete('/mcp/keys/$id', token: await _auth.getAccessToken());
  }
}
