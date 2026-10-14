import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:sinclear_beyond/features/calendar/models/calendar_models.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_item.dart';
import 'package:sinclear_beyond/features/travel/models/travel_models.dart';
import 'package:sinclear_beyond/features/widgets/widget_payloads.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  NotificationItem forumNotification(
    String id,
    String type, {
    String forum = 'f',
    String post = 'p',
  }) {
    return NotificationItem(
      id: id,
      type: type,
      title: 'Neue Antwort',
      text: null,
      data: [
        NotificationRelation(
          relation: 'parent_forum',
          object: 'Forum',
          identifier: forum,
        ),
        NotificationRelation(
          relation: 'parent_post',
          object: 'ForumPost',
          identifier: post,
        ),
      ],
      createdAt: DateTime.utc(2026, 1, 1),
    );
  }

  group('ActivityPayload.fromUnread', () {
    test('zählt nur Forum-Typen und dedupliziert Posts', () {
      final unread = [
        forumNotification('1', 'forum_reply', post: 'p1'),
        // zweite Benachrichtigung zum selben Post → dedupliziert
        forumNotification('2', 'forum_comment', post: 'p1'),
        forumNotification('3', 'forum_reply', post: 'p2'),
        NotificationItem(
          id: '4',
          type: 'direct_message',
          data: [
            const NotificationRelation(
              relation: 'conversation',
              object: 'Conversation',
              identifier: 'c1',
            ),
          ],
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ];

      final payload = ActivityPayload.fromUnread(unread);

      expect(payload.total, 3);
      expect(payload.items.length, 2);
      expect(payload.items.first.route, '/forum/f/beitrag/p1');
    });

    test('ignoriert Einträge ohne Post-Relation', () {
      final unread = [
        NotificationItem(
          id: '1',
          type: 'forum_reply',
          data: const [],
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      ];
      final payload = ActivityPayload.fromUnread(unread);

      expect(payload.total, 1);
      expect(payload.items, isEmpty);
    });
  });

  group('TodayPayload.fromEntries', () {
    test('baut die Route abhängig vom Typ', () {
      final entries = [
        const CalendarEntry(
          type: CalendarEntryType.calendarEvent,
          id: 'e1',
          title: 'Meeting',
        ),
        const CalendarEntry(
          type: CalendarEntryType.travelEvent,
          id: 'ev1',
          title: 'Konzert',
        ),
        const CalendarEntry(type: CalendarEntryType.trip, id: 't1', title: 'Berlin'),
        const CalendarEntry(
          type: CalendarEntryType.birthday,
          id: 'b1',
          title: 'Geburtstag: Max',
          detail: {'userId': 'u1'},
        ),
      ];

      final payload = TodayPayload.fromEntries(entries);

      expect(payload.items.map((e) => e.route), [
        '/kalender/e1',
        '/reisen/einzelevent/ev1',
        '/reisen/t1',
        '/kontakte/u1',
      ]);
    });
  });

  group('TripPayload.fromTrips', () {
    final now = DateTime(2026, 10, 10);

    test('wählt die nächste bevorstehende Reise', () {
      final trips = [
        TravelTrip(
          id: 'past',
          name: 'Vergangen',
          hastickets: '0',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 5),
        ),
        TravelTrip(
          id: 'next',
          name: 'Berlin',
          hastickets: '0',
          startDate: DateTime(2026, 10, 20),
          endDate: DateTime(2026, 10, 25),
        ),
      ];

      final payload = TripPayload.fromTrips(trips, now);

      expect(payload.route, '/reisen/next');
      expect(payload.title, 'Berlin');
      expect(payload.daysUntil, 10);
    });

    test('liefert einen leeren Payload ohne bevorstehende Reise', () {
      final trips = [
        TravelTrip(
          id: 'past',
          name: 'Vergangen',
          hastickets: '0',
          startDate: DateTime(2026, 8, 1),
          endDate: DateTime(2026, 8, 5),
        ),
      ];

      expect(TripPayload.fromTrips(trips, now).isEmpty, isTrue);
    });
  });
}
