import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';
import 'package:sinclear_beyond/features/stories/services/stories_service.dart';

class _MockApiClient extends ApiClient {
  final List<Map<String, dynamic>> feedResponses = [];
  final List<String> calledPaths = [];
  bool throwOnGet = false;

  _MockApiClient() : super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    calledPaths.add(path);
    if (throwOnGet) throw const ApiException(errorCode: 'boom', statusCode: 500);
    if (feedResponses.isNotEmpty) return feedResponses.removeAt(0);
    return {'data': <Map<String, dynamic>>[]};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    calledPaths.add(path);
    return {};
  }
}

class _FakeAuth extends AuthService {
  _FakeAuth(ApiClient api) : super(api: api, storage: TokenStorage());

  @override
  Future<String> getAccessToken() async => 'test-token';
}

Map<String, dynamic> _feedJson(List<Map<String, dynamic>> stories) => {
  'data': [
    {
      'userId': 'u1',
      'displayName': 'Marc',
      'avatar': null,
      'stories': stories,
    },
  ],
};

Map<String, dynamic> _storyJson(String id, {bool viewed = false}) => {
  'id': id,
  'image': 'aGVsbG8=',
  'caption': null,
  'createdAt': '2026-08-15 12:00:00',
  'expiresAt': '2026-08-22 12:00:00',
  'viewed': viewed,
};

void main() {
  late _MockApiClient api;
  late StoriesService service;
  var notified = 0;

  setUp(() {
    api = _MockApiClient();
    service = StoriesService(api: api, auth: _FakeAuth(api));
    notified = 0;
    service.addListener(() => notified++);
  });

  tearDown(() {
    service.dispose();
  });

  test('refreshFeed lädt den Feed und übernimmt den Server-Gesehen-Status',
      () async {
    api.feedResponses.add(_feedJson([
      _storyJson('s1', viewed: true),
      _storyJson('s2'),
    ]));

    await service.refreshFeed();

    expect(service.groups, isNotNull);
    expect(service.groups!.single.stories, hasLength(2));
    expect(service.isViewed('s1'), isTrue);
    expect(service.isViewed('s2'), isFalse);
    expect(service.error, isNull);
    expect(notified, greaterThanOrEqualTo(1));
  });

  test('markViewed meldet idempotent und hält die Session-Markierung', () async {
    api.feedResponses.add(_feedJson([_storyJson('s1')]));
    await service.refreshFeed();

    await service.markViewed('s1');
    await service.markViewed('s1');
    expect(
      api.calledPaths.where((p) => p == '/stories/s1/view'),
      hasLength(1),
    );

    // Der Server kennt die Markierung beim nächsten Abruf noch nicht —
    // der Ring darf nicht zurückblinken.
    api.feedResponses.add(_feedJson([_storyJson('s1')]));
    await service.refreshFeed();
    expect(service.isViewed('s1'), isTrue);
  });

  test('Fehler landen in error und alte Daten bleiben sichtbar', () async {
    api.feedResponses.add(_feedJson([_storyJson('s1')]));
    await service.refreshFeed();

    api.throwOnGet = true;
    await service.refreshFeed();

    expect(service.error, isNotNull);
    expect(service.groups, isNotNull);
    expect(service.groups!.single.stories.single.id, 's1');
  });
}
