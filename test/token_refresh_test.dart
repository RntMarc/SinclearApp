import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/network/token_refresh.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  int nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  test('nutzt gecachten Access-Token ohne erneuten Refresh', () async {
    SharedPreferences.setMockInitialValues({
      'access_token': 'cached-access',
      'access_token_expires_at': nowSeconds() + 3600,
    });

    var refreshCalls = 0;
    final api = ApiClient(
      baseUrl: 'http://test',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          refreshCalls++;
        }
        return http.Response('{}', 200);
      }),
    );
    final storage = TokenStorage();

    final token = await refreshAccessToken(api, storage);

    expect(token, 'cached-access');
    expect(refreshCalls, 0, reason: 'kein /auth/refresh bei gültigem Cache');
  });

  test('rotiert nur bei abgelaufenem Cache und speichert neue Tokens', () async {
    SharedPreferences.setMockInitialValues({
      'refresh_token': 'refresh-1',
      // Access-Token abgelaufen (in der Vergangenheit).
      'access_token_expires_at': nowSeconds() - 60,
    });

    final api = ApiClient(
      baseUrl: 'http://test',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(
            jsonEncode({
              'access_token': 'access-2',
              'expires_in': 3600,
              'refresh_token': 'refresh-2',
              'expires_at': 0,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      }),
    );
    final storage = TokenStorage();

    final token = await refreshAccessToken(api, storage);

    expect(token, 'access-2');
    expect(await storage.getRefreshToken(), 'refresh-2');
    expect(await storage.getAccessToken(), 'access-2');
  });

  test('verwirft Ergebnis, wenn während des Refreshes ausgeloggt wurde', () async {
    SharedPreferences.setMockInitialValues({
      'refresh_token': 'refresh-1',
    });

    final storage = TokenStorage();
    final api = ApiClient(
      baseUrl: 'http://test',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          // Simuliert einen Logout während des Refreshes (Session-Version++).
          await storage.incrementSessionVersion();
          return http.Response(
            jsonEncode({
              'access_token': 'access-2',
              'expires_in': 3600,
              'refresh_token': 'refresh-2',
              'expires_at': 0,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      }),
    );

    final token = await refreshAccessToken(api, storage);

    expect(token, isNull);
    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), 'refresh-1',
        reason: 'alter Refresh-Token bleibt, da Ergebnis verworfen wurde');
  });
}
