import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_type_preference.dart';

void main() {
  group('NotificationPreferencesResponse.fromJson', () {
    test('parst die API-Map in eine Präferenz-Map', () {
      final response = NotificationPreferencesResponse.fromJson({
        'data': {
          'forum_comment': {
            'state': 'custom',
            'customAllowed': true,
            'customData': {
              'forumIds': ['f1', 'f2'],
            },
          },
          'story_post': {
            'state': 'enabled',
            'customAllowed': true,
            'customData': null,
          },
          'trip_user_added': {
            'state': 'enabled',
            'customAllowed': false,
            'customData': null,
          },
        },
      });

      expect(
        response.data.keys,
        containsAll(['forum_comment', 'story_post', 'trip_user_added']),
      );

      final forum = response.data['forum_comment']!;
      expect(forum.type, 'forum_comment');
      expect(forum.state, NotificationPreferenceState.custom);
      expect(forum.customAllowed, isTrue);
      expect(forum.denylistIds('forumIds'), ['f1', 'f2']);
      expect(forum.denylistIds('userIds'), isEmpty);

      final story = response.data['story_post']!;
      expect(story.state, NotificationPreferenceState.enabled);
      expect(story.customAllowed, isTrue);
      expect(story.customData, isNull);

      final trip = response.data['trip_user_added']!;
      expect(trip.state, NotificationPreferenceState.enabled);
      expect(trip.customAllowed, isFalse);
    });

    test('unbekannter State fällt auf enabled zurück', () {
      final response = NotificationPreferencesResponse.fromJson({
        'data': {
          'forum_reply': {'state': 'komisch', 'customAllowed': true},
        },
      });

      expect(
        response.data['forum_reply']!.state,
        NotificationPreferenceState.enabled,
      );
    });

    test('leere Antwort ergibt eine leere Map', () {
      final response = NotificationPreferencesResponse.fromJson({'data': {}});
      expect(response.data, isEmpty);
    });

    test('fehlende data ergibt eine leere Map', () {
      final response = NotificationPreferencesResponse.fromJson({});
      expect(response.data, isEmpty);
    });
  });

  group('NotificationTypePreference.toRequestJson', () {
    test('enabled ohne customData', () {
      const pref = NotificationTypePreference(
        type: 'story_post',
        state: NotificationPreferenceState.enabled,
        customAllowed: true,
      );

      expect(pref.toRequestJson(), {'type': 'story_post', 'state': 'enabled'});
    });

    test('disabled ohne customData', () {
      const pref = NotificationTypePreference(
        type: 'trip_info_changed',
        state: NotificationPreferenceState.disabled,
        customAllowed: false,
      );

      expect(pref.toRequestJson(), {
        'type': 'trip_info_changed',
        'state': 'disabled',
      });
    });

    test('custom mit Denylist', () {
      const pref = NotificationTypePreference(
        type: 'forum_comment',
        state: NotificationPreferenceState.custom,
        customAllowed: true,
        customData: {
          'forumIds': ['f1', 'f2'],
        },
      );

      expect(pref.toRequestJson(), {
        'type': 'forum_comment',
        'state': 'custom',
        'customData': {
          'forumIds': ['f1', 'f2'],
        },
      });
    });

    test('custom mit leerer Denylist bleibt custom', () {
      const pref = NotificationTypePreference(
        type: 'story_post',
        state: NotificationPreferenceState.custom,
        customAllowed: true,
        customData: {'userIds': <String>[]},
      );

      expect(pref.toRequestJson(), {
        'type': 'story_post',
        'state': 'custom',
        'customData': {'userIds': <String>[]},
      });
    });
  });

  group('NotificationTypePreference.denylistIds', () {
    test('liefert nur Strings und ignoriert fremde Typen', () {
      const pref = NotificationTypePreference(
        type: 'forum_comment',
        state: NotificationPreferenceState.custom,
        customAllowed: true,
        customData: {
          'forumIds': ['f1', 42, null, 'f2'],
        },
      );

      expect(pref.denylistIds('forumIds'), ['f1', 'f2']);
    });

    test('ohne customData leer', () {
      const pref = NotificationTypePreference(
        type: 'forum_comment',
        state: NotificationPreferenceState.enabled,
        customAllowed: true,
      );

      expect(pref.denylistIds('forumIds'), isEmpty);
    });
  });
}
