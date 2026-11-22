import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';
import 'package:sinclear_beyond/features/stories/models/stories_models.dart';
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
    if (throwOnGet)
      throw const ApiException(errorCode: 'boom', statusCode: 500);
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

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    calledPaths.add(path);
    return {
      'data': [
        {
          'userId': 'me',
          'displayName': 'Ich',
          'avatar': null,
          'emoji': body?['emoji'],
          'createdAt': '2026-11-22 10:00:00',
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
    bool parseResponse = false,
  }) async {
    calledPaths.add(path);
    return {'data': <Map<String, dynamic>>[]};
  }
}

class _FakeAuth extends AuthService {
  _FakeAuth(ApiClient api) : super(api: api, storage: TokenStorage());

  @override
  Future<String> getAccessToken() async => 'test-token';
}

Map<String, dynamic> _feedJson(List<Map<String, dynamic>> stories) => {
  'data': [
    {'userId': 'u1', 'displayName': 'Marc', 'avatar': null, 'stories': stories},
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

  test(
    'refreshFeed lädt den Feed und übernimmt den Server-Gesehen-Status',
    () async {
      api.feedResponses.add(
        _feedJson([_storyJson('s1', viewed: true), _storyJson('s2')]),
      );

      await service.refreshFeed();

      expect(service.groups, isNotNull);
      expect(service.groups!.single.stories, hasLength(2));
      expect(service.isViewed('s1'), isTrue);
      expect(service.isViewed('s2'), isFalse);
      expect(service.error, isNull);
      expect(notified, greaterThanOrEqualTo(1));
    },
  );

  test(
    'markViewed meldet idempotent und hält die Session-Markierung',
    () async {
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
    },
  );

  test('Fehler landen in error und alte Daten bleiben sichtbar', () async {
    api.feedResponses.add(_feedJson([_storyJson('s1')]));
    await service.refreshFeed();

    api.throwOnGet = true;
    await service.refreshFeed();

    expect(service.error, isNotNull);
    expect(service.groups, isNotNull);
    expect(service.groups!.single.stories.single.id, 's1');
  });

  test('react/removeReaction treffen die richtigen Endpunkte', () async {
    final updated = await service.react('s1', '🔥');
    expect(api.calledPaths, contains('/stories/s1/reaction'));
    expect(updated.single.emoji, '🔥');
    expect(updated.single.isMine('me'), isTrue);

    final removed = await service.removeReaction('s1');
    expect(api.calledPaths, contains('/stories/s1/reaction'));
    expect(removed, isEmpty);
  });

  test('StoryReaction.fromJson parst Felder und isMine', () {
    final reaction = StoryReaction.fromJson({
      'userId': 'u2',
      'displayName': 'Bob',
      'avatar': 'abc',
      'emoji': '🎉',
      'createdAt': '2026-11-22 10:00:00',
    });

    expect(reaction.emoji, '🎉');
    expect(reaction.displayName, 'Bob');
    expect(reaction.isMine('u2'), isTrue);
    expect(reaction.isMine('u1'), isFalse);
    expect(reaction.isMine(null), isFalse);
  });
}
