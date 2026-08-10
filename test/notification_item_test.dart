import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_item.dart';

void main() {
  group('NotificationItem.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': '01923456-7890-7abc-def0-123456789012',
        'type': 'forum_reply',
        'title': 'Neue Antwort',
        'body': 'Jemand hat auf deinen Beitrag geantwortet.',
        'data': {'route': '/forum/42'},
        'createdAt': '2026-08-10 14:30:00',
      };

      final item = NotificationItem.fromJson(json);

      expect(item.id, '01923456-7890-7abc-def0-123456789012');
      expect(item.type, 'forum_reply');
      expect(item.title, 'Neue Antwort');
      expect(item.body, 'Jemand hat auf deinen Beitrag geantwortet.');
      expect(item.data, {'route': '/forum/42'});
      expect(item.createdAt, DateTime(2026, 8, 10, 14, 30, 0));
    });

    test('handles null data field', () {
      final json = {
        'id': '01923456-7890-7abc-def0-123456789012',
        'type': 'event_reminder',
        'title': 'Erinnerung',
        'body': 'Event beginnt bald.',
        'data': null,
        'createdAt': '2026-08-10 14:30:00',
      };

      final item = NotificationItem.fromJson(json);

      expect(item.data, isNull);
    });

    test('parses different notification types', () {
      final types = [
        'forum_reply',
        'forum_comment',
        'event_reminder',
        'poll_invitation',
        'travel_update',
        'feedback_status',
      ];

      for (final type in types) {
        final json = {
          'id': 'test-id',
          'type': type,
          'title': 'Test',
          'body': 'Body',
          'data': null,
          'createdAt': '2026-08-10 14:30:00',
        };

        final item = NotificationItem.fromJson(json);
        expect(item.type, type);
      }
    });
  });
}
