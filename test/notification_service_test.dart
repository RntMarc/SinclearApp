import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_item.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_type_preference.dart';
import 'package:sinclear_beyond/features/notifications/services/notification_service.dart';

class MockApiClient extends ApiClient {
  final List<Map<String, dynamic>> responses = [];
  int callIndex = 0;
  final List<String> calledPaths = [];
  final List<Map<String, String?>?> calledQueryParams = [];
  final List<Map<String, dynamic>?> calledBodies = [];

  MockApiClient() : super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    calledPaths.add(path);
    calledQueryParams.add(queryParams);
    if (callIndex < responses.length) {
      return responses[callIndex++];
    }
    return {'notifications': []};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    calledPaths.add(path);
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    calledPaths.add(path);
    calledBodies.add(body);
    if (callIndex < responses.length) {
      return responses[callIndex++];
    }
    return {'data': {}};
  }
}

void main() {
  late NotificationService service;
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
    service = NotificationService(api: mockApi);
  });

  tearDown(() {
    service.dispose();
  });

  group('startPolling', () {
    test('triggers poll immediately', () async {
      mockApi.responses.add({
        'notifications': [
          {
            'id': '1',
            'type': 'forum_reply',
            'data': const <Map<String, dynamic>>[],
            'createdAt': '2026-08-10 14:30:00',
          },
        ],
      });

      service.startPolling(token: 'test-token');

      await Future.delayed(const Duration(milliseconds: 100));

      expect(mockApi.calledPaths, contains('/notifications'));
    });
  });

  group('_poll', () {
    test('adds items to stream', () async {
      final completer = Completer<List<dynamic>>();
      mockApi.responses.add({
        'notifications': [
          {
            'id': '1',
            'type': 'forum_reply',
            'data': const <Map<String, dynamic>>[],
            'createdAt': '2026-08-10 14:30:00',
          },
        ],
      });

      service.notifications.listen((items) {
        if (!completer.isCompleted) completer.complete(items);
      });

      service.startPolling(token: 'test-token');

      final items = await completer.future.timeout(const Duration(seconds: 1));

      expect(items.length, 1);
      expect(items.first.id, '1');
      expect(items.first.type, 'forum_reply');
    });

    test('empty response adds nothing to stream', () async {
      mockApi.responses.add({'notifications': []});

      service.startPolling(token: 'test-token');

      await Future.delayed(const Duration(milliseconds: 100));

      expect(mockApi.calledPaths, contains('/notifications'));
    });

    test('sets _lastSeen after first poll', () async {
      mockApi.responses.add({
        'notifications': [
          {
            'id': '1',
            'type': 'forum_reply',
            'data': const <Map<String, dynamic>>[],
            'createdAt': '2026-08-10 14:30:00',
          },
        ],
      });
      mockApi.responses.add({'notifications': []});

      service.startPolling(
        token: 'test-token',
        interval: const Duration(milliseconds: 50),
      );
      await Future.delayed(const Duration(milliseconds: 200));

      expect(mockApi.calledQueryParams.length, greaterThan(1));
      expect(mockApi.calledQueryParams[1], isNotNull);
      expect(mockApi.calledQueryParams[1]!['since'], isNotNull);
    });

    test('since keeps millisecond precision (exclusive boundary)', () async {
      mockApi.responses.add({
        'notifications': [
          {
            'id': '1',
            'type': 'forum_reply',
            'data': const <Map<String, dynamic>>[],
            'createdAt': '2026-08-10 14:30:00.495',
          },
        ],
      });
      mockApi.responses.add({'notifications': []});

      service.startPolling(
        token: 'test-token',
        interval: const Duration(milliseconds: 50),
      );
      await Future.delayed(const Duration(milliseconds: 200));

      final since = mockApi.calledQueryParams[1]!['since']!;
      expect(since, matches(RegExp(r'\.\d{3}$')));
      expect(since, contains('14:30:00.495'));
    });

    test('already shown notification is not emitted twice', () async {
      final item = {
        'id': '1',
        'type': 'forum_reply',
        'data': const <Map<String, dynamic>>[],
        'createdAt': '2026-08-10 14:30:00',
      };
      mockApi.responses.add({
        'notifications': [item],
      });
      mockApi.responses.add({
        'notifications': [item],
      });

      final emitted = <int>[];
      service.notifications.listen((items) => emitted.add(items.length));

      service.startPolling(
        token: 'test-token',
        interval: const Duration(milliseconds: 50),
      );
      await Future.delayed(const Duration(milliseconds: 200));

      expect(emitted, [1]);
    });

    test('startPolling does not restart an active poller', () async {
      mockApi.responses.add({
        'notifications': [
          {
            'id': '1',
            'type': 'forum_reply',
            'data': const <Map<String, dynamic>>[],
            'createdAt': '2026-08-10 14:30:00',
          },
        ],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));
      final callCount = mockApi.calledPaths.length;

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(mockApi.calledPaths.length, callCount);
    });
  });

  group('stopPolling', () {
    test('stops the timer', () async {
      mockApi.responses.add({'notifications': []});
      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 50));

      service.stopPolling();

      await Future.delayed(const Duration(milliseconds: 100));

      final initialCallCount = mockApi.calledPaths.length;
      await Future.delayed(const Duration(milliseconds: 200));

      expect(mockApi.calledPaths.length, initialCallCount);
    });
  });

  group('markRead', () {
    test('sends ids to API', () async {
      await service.markRead(['id1', 'id2'], token: 'test-token');

      expect(mockApi.calledPaths, contains('/notifications/read'));
    });

    test('empty list does not call API', () async {
      await service.markRead([], token: 'test-token');

      expect(mockApi.calledPaths, isEmpty);
    });
  });

  Map<String, dynamic> forumNotification(
    String id,
    String type,
    String forumId,
    String postId,
  ) => {
    'id': id,
    'type': type,
    'data': [
      {'relation': 'parent_forum', 'object': 'Forum', 'identifier': forumId},
      {'relation': 'parent_post', 'object': 'ForumPost', 'identifier': postId},
    ],
    'createdAt': '2026-08-10 14:30:00',
  };

  group('unread registry', () {
    test('poll seeds registry and exposes forum/post ids', () async {
      mockApi.responses.add({
        'notifications': [
          forumNotification('1', 'forum_reply', 'forumA', 'post1'),
          forumNotification('2', 'forum_comment', 'forumB', 'post2'),
        ],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(service.hasUnreadForumContent, isTrue);
      expect(service.unreadForumIds, {'forumA', 'forumB'});
      expect(service.unreadPostIdsForForum('forumA'), {'post1'});
      expect(service.unreadIdsForPost('post1'), ['1']);
    });

    test('markRead removes ids from the registry', () async {
      mockApi.responses.add({
        'notifications': [
          forumNotification('1', 'forum_reply', 'forumA', 'post1'),
        ],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(service.hasUnreadForumContent, isTrue);

      await service.markRead(['1'], token: 'test-token');

      expect(service.hasUnreadForumContent, isFalse);
      expect(service.unreadIdsForPost('post1'), isEmpty);
    });

    test('refreshUnread replaces registry with server state', () async {
      mockApi.responses.add({
        'notifications': [
          forumNotification('1', 'forum_reply', 'forumA', 'post1'),
        ],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(service.unreadForumIds, {'forumA'});

      mockApi.responses.add({
        'notifications': [
          forumNotification('2', 'forum_comment', 'forumB', 'post2'),
        ],
      });
      await service.refreshUnread(token: 'test-token');

      expect(service.unreadForumIds, {'forumB'});
      expect(service.unreadIdsForPost('post1'), isEmpty);
    });

    test('unreadIdsForStory finds story notifications, not forum', () async {
      mockApi.responses.add({
        'notifications': [
          {
            'id': 's1',
            'type': 'story_post',
            'data': [
              {'relation': 'story', 'object': 'Story', 'identifier': 'story1'},
            ],
            'createdAt': '2026-08-10 14:30:00',
          },
        ],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(service.unreadIdsForStory('story1'), ['s1']);
      expect(service.hasUnreadForumContent, isFalse);
    });

    test('clear empties the registry', () async {
      mockApi.responses.add({
        'notifications': [
          forumNotification('1', 'forum_reply', 'forumA', 'post1'),
        ],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(service.hasUnreadForumContent, isTrue);

      service.clear();

      expect(service.hasUnreadForumContent, isFalse);
    });

    test('registerIncoming adds an item to the registry', () {
      service.registerIncoming(
        NotificationItem(
          id: 'x',
          type: 'forum_reply',
          data: const [
            NotificationRelation(
              relation: 'parent_forum',
              object: 'Forum',
              identifier: 'forumA',
            ),
            NotificationRelation(
              relation: 'parent_post',
              object: 'ForumPost',
              identifier: 'post1',
            ),
          ],
          createdAt: DateTime.utc(2026, 8, 10, 14, 30),
        ),
      );

      expect(service.unreadForumIds, {'forumA'});
    });
  });

  Map<String, dynamic> tripNotification(
    String id,
    String type,
    String tripId,
  ) => {
    'id': id,
    'type': type,
    'data': [
      {'relation': 'trip', 'object': 'Trip', 'identifier': tripId},
    ],
    'createdAt': '2026-08-10 14:30:00',
  };

  Map<String, dynamic> standaloneEventNotification(
    String id,
    String type,
    String eventId,
  ) => {
    'id': id,
    'type': type,
    'data': [
      {'relation': 'event', 'object': 'Event', 'identifier': eventId},
    ],
    'createdAt': '2026-08-10 14:30:00',
  };

  group('trip unread registry', () {
    test('poll seeds registry and exposes trip ids', () async {
      mockApi.responses.add({
        'notifications': [
          tripNotification('1', 'trip_user_added', 'tripA'),
          tripNotification('2', 'trip_ticket_added', 'tripB'),
        ],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(service.hasUnreadTripContent, isTrue);
      expect(service.unreadTripIds, {'tripA', 'tripB'});
      expect(service.unreadIdsForTrip('tripA'), ['1']);
    });

    test('markRead removes trip ids from the registry', () async {
      mockApi.responses.add({
        'notifications': [tripNotification('1', 'trip_user_added', 'tripA')],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(service.hasUnreadTripContent, isTrue);

      await service.markRead(['1'], token: 'test-token');

      expect(service.hasUnreadTripContent, isFalse);
      expect(service.unreadIdsForTrip('tripA'), isEmpty);
    });

    test('clear empties the trip registry', () async {
      mockApi.responses.add({
        'notifications': [tripNotification('1', 'trip_user_added', 'tripA')],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(service.hasUnreadTripContent, isTrue);

      service.clear();

      expect(service.hasUnreadTripContent, isFalse);
    });
  });

  group('standalone event unread registry', () {
    test('poll seeds registry and exposes event ids', () async {
      mockApi.responses.add({
        'notifications': [
          standaloneEventNotification(
            '1',
            'standalone_event_user_added',
            'eventA',
          ),
          standaloneEventNotification(
            '2',
            'standalone_event_ticket_added',
            'eventB',
          ),
        ],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(service.hasUnreadStandaloneEventContent, isTrue);
      expect(service.unreadStandaloneEventIds, {'eventA', 'eventB'});
      expect(service.unreadIdsForStandaloneEvent('eventA'), ['1']);
    });

    test('markRead removes event ids from the registry', () async {
      mockApi.responses.add({
        'notifications': [
          standaloneEventNotification(
            '1',
            'standalone_event_user_added',
            'eventA',
          ),
        ],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(service.hasUnreadStandaloneEventContent, isTrue);

      await service.markRead(['1'], token: 'test-token');

      expect(service.hasUnreadStandaloneEventContent, isFalse);
      expect(service.unreadIdsForStandaloneEvent('eventA'), isEmpty);
    });

    test('clear empties the event registry', () async {
      mockApi.responses.add({
        'notifications': [
          standaloneEventNotification(
            '1',
            'standalone_event_user_added',
            'eventA',
          ),
        ],
      });

      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(service.hasUnreadStandaloneEventContent, isTrue);

      service.clear();

      expect(service.hasUnreadStandaloneEventContent, isFalse);
    });
  });

  group('notification preferences', () {
    test('getPreferences parses the API map', () async {
      mockApi.responses.add({
        'data': {
          'forum_comment': {
            'state': 'custom',
            'customAllowed': true,
            'customData': {
              'forumIds': ['f1'],
            },
          },
          'story_post': {
            'state': 'enabled',
            'customAllowed': true,
            'customData': null,
          },
        },
      });

      final prefs = await service.getPreferences(token: 'test-token');

      expect(mockApi.calledPaths, contains('/notifications/preferences'));
      expect(prefs.keys, containsAll(['forum_comment', 'story_post']));
      expect(prefs['forum_comment']!.state, NotificationPreferenceState.custom);
      expect(prefs['forum_comment']!.denylistIds('forumIds'), ['f1']);
    });

    test(
      'updatePreferences sends only changed types and returns full map',
      () async {
        mockApi.responses.add({
          'data': {
            'story_post': {
              'state': 'disabled',
              'customAllowed': true,
              'customData': null,
            },
          },
        });

        final updated = await service.updatePreferences([
          const NotificationTypePreference(
            type: 'story_post',
            state: NotificationPreferenceState.disabled,
            customAllowed: true,
          ),
        ], token: 'test-token');

        expect(mockApi.calledPaths, contains('/notifications/preferences'));
        expect(mockApi.calledBodies.last, {
          'preferences': [
            {'type': 'story_post', 'state': 'disabled'},
          ],
        });
        expect(
          updated['story_post']!.state,
          NotificationPreferenceState.disabled,
        );
      },
    );

    test('updatePreferences sends customData for custom state', () async {
      mockApi.responses.add({'data': {}});

      await service.updatePreferences([
        const NotificationTypePreference(
          type: 'forum_reply',
          state: NotificationPreferenceState.custom,
          customAllowed: true,
          customData: {
            'forumIds': ['f1', 'f2'],
          },
        ),
      ], token: 'test-token');

      expect(mockApi.calledBodies.last, {
        'preferences': [
          {
            'type': 'forum_reply',
            'state': 'custom',
            'customData': {
              'forumIds': ['f1', 'f2'],
            },
          },
        ],
      });
    });
  });
}
