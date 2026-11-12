import 'package:shared_preferences/shared_preferences.dart';

/// Persistiert Auth-Tokens über die `SharedPreferences`.
///
/// `ponytail:` Der Access-Token wird ebenfalls hier abgelegt (statt nur im
/// RAM), damit er zwischen dem Haupt-Isolate und den Hintergrund-Isolates
/// (Foreground-Service, WorkManager, Widget-Sync) geteilt wird. Das verhindert,
/// dass jeder Hintergrund-Poll den Refresh-Token unnötig rotiert.
///
/// Upgrade: Refresh-Token in `flutter_secure_storage` ablegen (Keychain/
/// Keystore) statt in den unverschlüsselten `SharedPreferences` — siehe
/// `docs/auth/login.md`, Client-Hinweis 1.
class TokenStorage {
  static const _refreshTokenKey = 'refresh_token';
  static const _refreshExpiresAtKey = 'refresh_expires_at';
  static const _accessTokenKey = 'access_token';
  static const _accessExpiryKey = 'access_token_expires_at';
  static const _refreshLockKey = 'token_refresh_lock_until';
  static const _sessionVersionKey = 'auth_session_version';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Lädt den `SharedPreferences`-Cache neu. Nötig, weil jeder Isolate seinen
  /// eigenen In-Memory-Cache hält: Ohne `reload()` sieht das Haupt-Isolate
  /// nicht, was ein Hintergrund-Isolate zuletzt geschrieben hat (und umgekehrt).
  Future<void> reload() async {
    final prefs = await _instance;
    await prefs.reload();
  }

  Future<void> saveRefreshToken(String token, int expiresAt) async {
    final prefs = await _instance;
    await prefs.setString(_refreshTokenKey, token);
    await prefs.setInt(_refreshExpiresAtKey, expiresAt);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _instance;
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> saveAccessToken(String token, int expiresAt) async {
    final prefs = await _instance;
    await prefs.setString(_accessTokenKey, token);
    await prefs.setInt(_accessExpiryKey, expiresAt);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _instance;
    return prefs.getString(_accessTokenKey);
  }

  Future<int> getAccessTokenExpiry() async {
    final prefs = await _instance;
    return prefs.getInt(_accessExpiryKey) ?? 0;
  }

  Future<void> clearAccessToken() async {
    final prefs = await _instance;
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_accessExpiryKey);
  }

  /// Versucht, den Refresh-Lock zu erwerben (Cross-Isolate-Koordination).
  ///
  /// Liefert `false`, wenn ein anderer Isolate gerade rotiert (Lock noch nicht
  /// abgelaufen). Der Lock läuft nach [leaseSeconds] automatisch ab, damit ein
  /// abgestürzter Isolate den Lock nicht dauerhaft hält.
  Future<bool> tryAcquireRefreshLock(int leaseSeconds) async {
    final prefs = await _instance;
    await prefs.reload();
    final now = DateTime.now().millisecondsSinceEpoch;
    final until = prefs.getInt(_refreshLockKey) ?? 0;
    if (now < until) return false;
    await prefs.setInt(_refreshLockKey, now + leaseSeconds * 1000);
    return true;
  }

  Future<void> releaseRefreshLock() async {
    final prefs = await _instance;
    await prefs.remove(_refreshLockKey);
  }

  /// Aktuelle Session-Version. Wird bei jedem Logout erhöht, damit ein
  /// Hintergrund-Isolate, der während des Logouts gerade einen Refresh
  /// durchführt, dessen Ergebnis verwerfen kann (kein „Geister-Re-Login“).
  Future<int> getSessionVersion() async {
    final prefs = await _instance;
    return prefs.getInt(_sessionVersionKey) ?? 0;
  }

  Future<void> incrementSessionVersion() async {
    final prefs = await _instance;
    final current = prefs.getInt(_sessionVersionKey) ?? 0;
    await prefs.setInt(_sessionVersionKey, current + 1);
  }

  Future<void> clearTokens() async {
    final prefs = await _instance;
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_refreshExpiresAtKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_accessExpiryKey);
  }
}
