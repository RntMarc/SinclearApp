import 'api_client.dart';
import '../storage/token_storage.dart';

/// Sicherheitspuffer gegen Uhrenabweichung (Clock-Skew) in Sekunden. Ein
/// Access-Token gilt clientseitig als abgelaufen, bevor der Server ihn
/// tatsächlich ablehnt — verhindert 401 wegen Sekunden-Versatz.
const int tokenClockSkewSeconds = 30;

/// Lease-Dauer des Cross-Isolate-Refresh-Locks in Sekunden.
const int _refreshLockLeaseSeconds = 15;

int get _nowSeconds => DateTime.now().millisecondsSinceEpoch ~/ 1000;

/// Liefert einen gültigen Access-Token.
///
/// Dies ist die **einzige** Stelle, die `POST /auth/refresh` aufrufen darf —
/// gemeinsamer Refresh-Pfad für das Haupt-Isolate (`AuthService`) und die
/// Hintergrund-Isolates (Foreground-Service, WorkManager, Widget-Sync).
///
/// Ablauf:
///  1. Gecachten Access-Token wiederverwenden, solange er (mit Puffer) gültig
///     ist — verhindert, dass jeder Hintergrund-Poll den Refresh-Token rotiert.
///  2. Cross-Isolate-Lock: nur ein Isolate rotiert gleichzeitig; andere warten
///     kurz und übernehmen dessen Ergebnis.
///  3. Erst dann tatsächlich `/auth/refresh` aufrufen und neue Tokens sichern.
Future<String?> refreshAccessToken(ApiClient api, TokenStorage storage) async {
  await storage.reload();
  final sessionVersion = await storage.getSessionVersion();

  final cached = await storage.getAccessToken();
  final cachedExpiry = await storage.getAccessTokenExpiry();
  if (cached != null && _nowSeconds < cachedExpiry - tokenClockSkewSeconds) {
    return cached;
  }

  var acquired = false;
  for (var attempt = 0; attempt < 10; attempt++) {
    if (await storage.tryAcquireRefreshLock(_refreshLockLeaseSeconds)) {
      acquired = true;
      break;
    }
    // Ein anderer Isolate rotiert gerade: kurz warten und dessen Ergebnis lesen.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await storage.reload();
    final c = await storage.getAccessToken();
    final e = await storage.getAccessTokenExpiry();
    if (c != null && _nowSeconds < e - tokenClockSkewSeconds) {
      return c;
    }
  }

  try {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) return null;

    final refreshed = await api.post(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    final accessToken = refreshed['access_token'] as String;
    final expiresIn = refreshed['expires_in'] as int;
    final newRefresh = refreshed['refresh_token'] as String?;
    final refreshExpiresAt = refreshed['expires_at'] as int? ?? 0;

    // Logout-Race-Schutz: Hat sich der Nutzer während des Refreshes
    // abgemeldet (Session-Version erhöht), das Ergebnis verwerfen — sonst
    // schreibt der Hintergrund-Isolate einen frischen Token zurück und der
    // Nutzer wäre beim nächsten Start unerwartet wieder eingeloggt.
    await storage.reload();
    if (await storage.getSessionVersion() != sessionVersion) {
      return null;
    }

    await storage.saveAccessToken(accessToken, _nowSeconds + expiresIn);
    if (newRefresh != null) {
      await storage.saveRefreshToken(newRefresh, refreshExpiresAt);
    }
    return accessToken;
  } finally {
    if (acquired) {
      await storage.releaseRefreshLock();
    }
  }
}
