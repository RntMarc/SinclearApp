import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/arcade/models/arcade_models.dart';
import 'package:sinclear_beyond/features/arcade/services/arcade_service.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';

class _MockApiClient extends ApiClient {
  _MockApiClient() : super(baseUrl: 'http://localhost');

  final List<String> paths = <String>[];
  Map<String, dynamic> response = <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    paths.add('GET $path');
    return response;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    paths.add('POST $path');
    return response;
  }
}

class _FakeAuth extends AuthService {
  _FakeAuth(ApiClient api) : super(api: api, storage: TokenStorage());

  @override
  Future<String> getAccessToken() async => 'test-token';
}

Map<String, dynamic> _gameJson({String scoreDirection = 'desc'}) =>
    <String, dynamic>{
      'id': 'g1',
      'slug': 'rocket-boost',
      'title': 'Rocket Boost',
      'description': 'Flieg die Rakete durch die Korridore.',
      'thumbnailUrl': null,
      'scoreDirection': scoreDirection,
      'isActive': true,
      'sortOrder': 1,
      'playUrl': 'https://example.com/arcade/rocket-boost/index.html',
      'createdAt': '2026-11-01T16:00:00Z',
      'updatedAt': '2026-11-01T16:00:00Z',
    };

void main() {
  late _MockApiClient api;
  late ArcadeService service;

  setUp(() {
    api = _MockApiClient();
    service = ArcadeService(api: api, auth: _FakeAuth(api));
  });

  test('listGames liest den Katalog', () async {
    api.response = <String, dynamic>{
      'data': <dynamic>[_gameJson()],
    };
    final games = await service.listGames();
    expect(api.paths.single, 'GET /arcade/games');
    expect(games.single.slug, 'rocket-boost');
    expect(games.single.title, 'Rocket Boost');
    expect(games.single.scoreDirection, ScoreDirection.desc);
  });

  test('listGames parst asc-Score-Richtung', () async {
    api.response = <String, dynamic>{
      'data': <dynamic>[_gameJson(scoreDirection: 'asc')],
    };
    final games = await service.listGames();
    expect(games.single.scoreDirection, ScoreDirection.asc);
  });

  test('startSession stellt ein Token aus', () async {
    api.response = <String, dynamic>{
      'token': 'abc123',
      'expiresAt': '2026-11-01T16:15:00Z',
      'playUrl':
          'https://example.com/arcade/rocket-boost/index.html#arcade_token=abc123',
    };
    final session = await service.startSession('rocket-boost');
    expect(api.paths.single, 'POST /arcade/games/rocket-boost/session');
    expect(session.token, 'abc123');
    expect(session.playUrl, contains('arcade_token=abc123'));
  });
}
