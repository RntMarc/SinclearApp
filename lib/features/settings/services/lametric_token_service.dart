import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/lametric_token_models.dart';

/// Verwaltet das LaMetric-Token des angemeldeten Nutzers
/// (Endpunkte `/lametric/token` der API).
///
/// Genau ein Token pro Nutzer, gültig 1 Jahr. Der Klartext ist jederzeit
/// abrufbar, [get] liefert daher `null`, wenn noch kein Token existiert.
class LaMetricTokenService {
  final ApiClient _api;
  final AuthService _auth;

  LaMetricTokenService({required this._api, required this._auth});

  /// Liefert das vorhandene Token oder `null`, wenn keines existiert.
  Future<LaMetricToken?> get() async {
    final data = await _api.get(
      '/lametric/token',
      token: await _auth.getAccessToken(),
    );
    final token = data['token'];
    if (token == null) return null;
    return LaMetricToken.fromJson(token as Map<String, dynamic>);
  }

  /// Erzeugt oder ersetzt das Token und gibt es inkl. Klartext zurück.
  ///
  /// Der Name ist nicht unterscheidungsberechtigt (es existiert ohnehin nur
  /// dieses eine Token für alle Apps und Uhren), daher wird ohne Rückfrage
  /// immer `Time` mitgesendet.
  Future<LaMetricToken> put() async {
    final data = await _api.put(
      '/lametric/token',
      body: {'label': 'Time'},
      token: await _auth.getAccessToken(),
    );
    return LaMetricToken.fromJson(data['token'] as Map<String, dynamic>);
  }

  /// Widerruft das Token; idempotent.
  Future<void> delete() async {
    await _api.delete('/lametric/token', token: await _auth.getAccessToken());
  }
}
