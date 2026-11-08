// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/arcade_models.dart';

/// Zugriff auf die selbst gehosteten Arcade-Browser-Spiele.
///
/// Katalog-/Session-Endpunkte erfordern ein JWT; die spiel-internen
/// Score-/Renew-Endpunkte authentifizieren sich über das ausgestellte
/// Session-Token und werden vom Spiel selbst (im Browser) aufgerufen.
class ArcadeService {
  ArcadeService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  final ApiClient _api;
  final AuthService _auth;

  Future<String> _token() => _auth.getAccessToken();

  /// Katalog der aktiven Spiele.
  Future<List<ArcadeGame>> listGames() async {
    final data = await _api.get('/arcade/games', token: await _token());
    final list = data['data'];
    if (list is! List) return const <ArcadeGame>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ArcadeGame.fromJson)
        .toList();
  }

  /// Stellt ein Session-Token aus und liefert die spielbare Session.
  Future<ArcadeSession> startSession(String slug) async {
    final data = await _api.post(
      '/arcade/games/$slug/session',
      token: await _token(),
    );
    return ArcadeSession.fromJson(data);
  }
}
