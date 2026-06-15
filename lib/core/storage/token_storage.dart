import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _refreshTokenKey = 'refresh_token';
  static const _expiresAtKey = 'refresh_expires_at';

  Future<void> saveRefreshToken(String token, int expiresAt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
    await prefs.setInt(_expiresAtKey, expiresAt);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiresAtKey);
  }
}
