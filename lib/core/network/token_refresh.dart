import 'api_client.dart';
import '../storage/token_storage.dart';

/// Tauscht das gespeicherte Refresh-Token gegen einen neuen Access-Token
/// (`POST /auth/refresh`) und persistiert ein ggf. mitgeliefertes neues
/// Refresh-Token. Liefert den neuen Access-Token oder `null`, wenn kein
/// Refresh-Token vorliegt.
///
/// Gemeinsam genutzt vom Benachrichtigungs-Polling und der Widget-
/// Synchronisation, damit die Refresh-Logik nicht dupliziert wird.
Future<String?> refreshAccessToken(ApiClient api, TokenStorage storage) async {
  final refreshToken = await storage.getRefreshToken();
  if (refreshToken == null) return null;

  final refreshed = await api.post(
    '/auth/refresh',
    body: {'refresh_token': refreshToken},
  );
  final accessToken = refreshed['access_token'] as String;
  final newRefresh = refreshed['refresh_token'] as String?;
  if (newRefresh != null) {
    await storage.saveRefreshToken(
      newRefresh,
      refreshed['expires_at'] as int? ?? 0,
    );
  }
  return accessToken;
}
