import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';
import 'package:sinclear_beyond/features/explore/services/explore_service.dart';
import 'package:sinclear_beyond/features/recipes/services/recipes_service.dart';

/// Fake-Client, der die HTTP-Aufrufe aufzeichnet statt sie auszuführen.
class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(baseUrl: 'https://test.local');

  final List<({String path, String? token})> getCalls = [];
  final Map<String, Map<String, dynamic>> responses = {};

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    getCalls.add((path: path, token: token));
    return responses[path] ??
        {
          'data': [],
          'meta': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 1},
        };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    return {
      'access_token': 'access-abc',
      'expires_in': 3600,
      'refresh_token': 'refresh-abc',
    };
  }
}

Future<AuthService> _auth(
  _RecordingApiClient api, {
  required bool loggedIn,
}) async {
  SharedPreferences.setMockInitialValues({
    if (loggedIn) 'refresh_token': 'refresh-abc',
    if (loggedIn) 'refresh_expires_at': 0,
  });
  final auth = AuthService(api: api, storage: TokenStorage());
  await auth.init();
  return auth;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Gast: Recipes- und Explore-Services nutzen /public-Endpunkte ohne Token',
    () async {
      final api = _RecordingApiClient()
        ..responses['/public/recipes/r1'] = {
          'data': {
            'id': 'r1',
            'title': 'Test',
            'category': 'sonstiges',
            'servings': 4,
            'createdAt': '2026-01-01 00:00:00',
            'updatedAt': '2026-01-01 00:00:00',
          },
        }
        ..responses['/public/explore/p1'] = {
          'data': {
            'id': 'p1',
            'name': 'Testort',
            'category': 'gastronomy',
            'createdAt': '2026-01-01 00:00:00',
            'lastUpdated': '2026-01-01 00:00:00',
          },
        };
      final auth = await _auth(api, loggedIn: false);
      final recipes = RecipesService(api: api, auth: auth);
      final explore = ExploreService(api: api, auth: auth);

      await recipes.list();
      await recipes.get('r1');
      await explore.list();
      await explore.random();
      await explore.search(q: 'pizza');
      await explore.get('p1');

      expect(api.getCalls.map((c) => c.path), [
        '/public/recipes',
        '/public/recipes/r1',
        '/public/explore',
        '/public/explore/random',
        '/public/explore/search',
        '/public/explore/p1',
      ]);
      expect(api.getCalls.every((c) => c.token == null), isTrue);
    },
  );

  test(
    'Eingeloggt: Services nutzen private Endpunkte mit Bearer-Token',
    () async {
      final api = _RecordingApiClient()
        ..responses['/user/me'] = {
          'data': {'onboardingCompleted': true},
        };
      final auth = await _auth(api, loggedIn: true);
      final recipes = RecipesService(api: api, auth: auth);
      final explore = ExploreService(api: api, auth: auth);

      await recipes.list();
      await explore.random();

      final calls = api.getCalls;
      final recipeCall = calls.singleWhere((c) => c.path == '/recipes');
      final exploreCall = calls.singleWhere((c) => c.path == '/explore/random');
      expect(recipeCall.token, 'access-abc');
      expect(exploreCall.token, 'access-abc');
    },
  );
}
