import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';
import 'package:sinclear_beyond/features/settings/services/lametric_token_service.dart';

class _MockApiClient extends ApiClient {
  final List<String> calls = [];
  Map<String, dynamic> nextResponse = {};
  Map<String, dynamic>? lastBody;

  _MockApiClient() : super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    calls.add('GET $path');
    return nextResponse;
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    calls.add('PUT $path');
    lastBody = body;
    return nextResponse;
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
    bool parseResponse = false,
  }) async {
    calls.add('DELETE $path');
    return {};
  }
}

class _FakeAuth extends AuthService {
  _FakeAuth(ApiClient api) : super(api: api, storage: TokenStorage());

  @override
  Future<String> getAccessToken() async => 'test-token';
}

Map<String, dynamic> _tokenJson({String token = 'abc123'}) => {
  'token': {
    'id': 't1',
    'label': 'Wohnzimmer',
    'token': token,
    'expiresAt': '2027-09-25 12:00:00',
    'lastUsedAt': null,
    'createdAt': '2026-09-25 12:00:00',
  },
};

void main() {
  late _MockApiClient api;
  late LaMetricTokenService service;

  setUp(() {
    api = _MockApiClient();
    service = LaMetricTokenService(api: api, auth: _FakeAuth(api));
  });

  test('get() liefert null, wenn die API token=null meldet', () async {
    api.nextResponse = {'token': null};
    expect(await service.get(), isNull);
    expect(api.calls, ['GET /lametric/token']);
  });

  test('get() parst das vorhandene Token inkl. Klartext', () async {
    api.nextResponse = _tokenJson();
    final token = await service.get();
    expect(token!.token, 'abc123');
    expect(token.label, 'Wohnzimmer');
    expect(token.lastUsedAt, isNull);
  });

  test('put() setzt ohne Rückfrage den festen Namen Time', () async {
    api.nextResponse = _tokenJson(token: 'neu456');
    final token = await service.put();
    expect(api.calls, ['PUT /lametric/token']);
    expect(api.lastBody, {'label': 'Time'});
    expect(token.token, 'neu456');
  });

  test('delete() ruft den Token-Endpunkt auf', () async {
    await service.delete();
    expect(api.calls, ['DELETE /lametric/token']);
  });
}
