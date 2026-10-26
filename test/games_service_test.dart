import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';
import 'package:sinclear_beyond/features/games/services/games_service.dart';

class _MockApiClient extends ApiClient {
  _MockApiClient() : super(baseUrl: 'http://localhost');

  final List<String> paths = <String>[];
  final List<Map<String, String>?> queries = <Map<String, String>?>[];
  final List<Map<String, dynamic>?> bodies = <Map<String, dynamic>?>[];
  Map<String, dynamic> response = <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    paths.add('GET $path');
    queries.add(queryParams);
    return response;
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    paths.add('PUT $path');
    bodies.add(body);
    return response;
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
    bool parseResponse = false,
  }) async {
    paths.add('DELETE $path');
    return response;
  }
}

class _FakeAuth extends AuthService {
  _FakeAuth(ApiClient api) : super(api: api, storage: TokenStorage());

  @override
  Future<String> getAccessToken() async => 'test-token';
}

Map<String, dynamic> _accountJson(String accountId) => <String, dynamic>{
  'id': 'a1',
  'userId': 'u1',
  'game': 'deadlock',
  'accountId': accountId,
  'displayName': 'Marc',
  'avatarUrl': null,
  'lastSyncedAt': null,
  'createdAt': '2026-10-25T14:00:00Z',
  'updatedAt': '2026-10-25T14:00:00Z',
};

Map<String, dynamic> _statsJson(String userId) => <String, dynamic>{
  'game': 'deadlock',
  'userId': userId,
  'accountId': '42',
  'stats': null,
  'lastRefreshedAt': '2026-10-25T14:00:00Z',
  'nextRefreshAt': '2026-10-25T15:00:00Z',
};

void main() {
  late _MockApiClient api;
  late GamesService service;

  setUp(() {
    api = _MockApiClient();
    service = GamesService(api: api, auth: _FakeAuth(api));
  });

  test('listMine liest die verknüpften Accounts', () async {
    api.response = <String, dynamic>{
      'data': <dynamic>[_accountJson('179673173')],
    };
    final accounts = await service.listMine();
    expect(api.paths.single, 'GET /user/me/games');
    expect(accounts.single.accountId, '179673173');
    expect(accounts.single.displayName, 'Marc');
  });

  test('link sendet die SteamID3 und liefert den Account', () async {
    api.response = <String, dynamic>{'data': _accountJson('179673173')};
    final account = await service.link('deadlock', '179673173');
    expect(api.paths.single, 'PUT /user/me/games/deadlock');
    expect(api.bodies.single, <String, dynamic>{'accountId': '179673173'});
    expect(account.game, 'deadlock');
  });

  test('unlink ruft DELETE auf', () async {
    await service.unlink('deadlock');
    expect(api.paths.single, 'DELETE /user/me/games/deadlock');
  });

  test('stats liest Einzelstatistiken', () async {
    api.response = <String, dynamic>{'data': _statsJson('u1')};
    final stats = await service.stats('deadlock', 'u1');
    expect(api.paths.single, 'GET /games/deadlock/stats/u1');
    expect(stats.userId, 'u1');
    expect(stats.nextRefreshAt, '2026-10-25T15:00:00Z');
  });

  test('batchStats chunked auf 100 Nutzer-IDs', () async {
    api.response = <String, dynamic>{
      'data': <dynamic>[_statsJson('u1')],
    };
    final ids = List<String>.generate(150, (index) => 'u$index');
    final result = await service.batchStats('deadlock', ids);

    expect(api.paths, <String>[
      'GET /games/deadlock/stats',
      'GET /games/deadlock/stats',
    ]);
    expect(api.queries[0]!['userIds']!.split(','), hasLength(100));
    expect(api.queries[1]!['userIds']!.split(','), hasLength(50));
    expect(result, hasLength(2)); // zwei Antworten mit je einem Eintrag
  });

  test('batchStats entfernt Duplikate und leere IDs', () async {
    api.response = <String, dynamic>{'data': <dynamic>[]};
    await service.batchStats('deadlock', <String>['u1', 'u1', ' ', 'u2']);
    expect(api.queries.single!['userIds'], 'u1,u2');
  });
}
