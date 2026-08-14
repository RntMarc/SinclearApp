import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/calendar/models/calendar_models.dart';

Map<String, dynamic> _entry({
  required String type,
  required String id,
  String? title,
  String? startTime,
  String? endTime,
  bool allDay = false,
  Map<String, dynamic> detail = const {},
}) {
  return {
    'type': type,
    'id': id,
    'title': title,
    'startTime': startTime,
    'endTime': endTime,
    'allDay': allDay,
    'detail': detail,
  };
}

void main() {
  group('CalendarEntry.fromJson', () {
    test('parst den kombinierten Feed mit allen fünf Typen', () {
      final json = {
        'data': [
          _entry(
            type: 'calendar_event',
            id: 'event-1',
            title: 'Team Meeting',
            startTime: '2026-07-01 10:00:00',
            endTime: '2026-07-01 11:00:00',
            detail: {'description': 'Weekly'},
          ),
          _entry(
            type: 'travel_event',
            id: 'travel-event-1',
            title: 'Konzert',
            startTime: '2026-07-02 20:00:00',
            endTime: '2026-07-02 23:00:00',
          ),
          _entry(
            type: 'trip',
            id: 'trip-1',
            title: 'Berlin',
            startTime: '2026-07-03 00:00:00',
            endTime: '2026-07-06 23:59:59',
            allDay: true,
          ),
          _entry(
            type: 'birthday',
            id: '2026-07-04-user-1',
            title: 'Geburtstag: Max',
            startTime: '2026-07-04 00:00:00',
            endTime: '2026-07-04 23:59:59',
            allDay: true,
            detail: {'userId': 'user-1'},
          ),
          _entry(
            type: 'pt_journey',
            id: 'journey-1',
            title: 'Hamburg → Berlin',
            startTime: '2026-07-05 08:00:00',
            endTime: '2026-07-05 10:30:00',
            detail: {'legs': <Map<String, dynamic>>[]},
          ),
        ],
        'meta': {'truncated': true, 'count': 5},
      };

      final response = CalendarAllResponse.fromJson(json);

      expect(response.data, hasLength(5));
      expect(response.truncated, isTrue);

      final event = response.data[0];
      expect(event.type, 'calendar_event');
      expect(event.id, 'event-1');
      expect(event.title, 'Team Meeting');
      expect(event.allDay, isFalse);
      expect(event.startTime!.toUtc(), DateTime.utc(2026, 7, 1, 10, 0, 0));
      expect(event.endTime!.toUtc(), DateTime.utc(2026, 7, 1, 11, 0, 0));
      expect(event.detail['description'], 'Weekly');

      expect(response.data[2].allDay, isTrue);
      expect(response.data[4].detail['legs'], isEmpty);
    });

    test('nullable Felder werden zu null, allDay defaultet auf false', () {
      final entry = CalendarEntry.fromJson(_entry(type: 'trip', id: 'trip-1'));

      expect(entry.title, isNull);
      expect(entry.startTime, isNull);
      expect(entry.endTime, isNull);
      expect(entry.allDay, isFalse);
      expect(entry.detail, isEmpty);
    });

    test('fehlende meta ergibt truncated == false', () {
      final response = CalendarAllResponse.fromJson({
        'data': [_entry(type: 'trip', id: 'trip-1')],
      });

      expect(response.truncated, isFalse);
    });
  });

  group('CalendarEntry.key und targetId', () {
    test('key kombiniert Typ und ID', () {
      final entry = CalendarEntry.fromJson(_entry(type: 'trip', id: 'trip-1'));

      expect(entry.key, 'trip:trip-1');
    });

    test('targetId ist für Nicht-Geburtstage die eigene ID', () {
      for (final type in [
        'calendar_event',
        'travel_event',
        'trip',
        'pt_journey',
      ]) {
        final entry = CalendarEntry.fromJson(_entry(type: type, id: 'some-id'));
        expect(entry.targetId, 'some-id', reason: type);
      }
    });

    test('targetId ist für Geburtstage die Nutzer-ID aus detail', () {
      final entry = CalendarEntry.fromJson(
        _entry(
          type: 'birthday',
          id: '2026-07-04-user-1',
          detail: {'userId': 'user-1'},
        ),
      );

      expect(entry.targetId, 'user-1');
    });

    test('Geburtstag ohne Nutzer-ID ergibt targetId null', () {
      final entry = CalendarEntry.fromJson(
        _entry(type: 'birthday', id: '2026-07-04-user-1'),
      );

      expect(entry.targetId, isNull);
    });
  });

  group('CalendarEntry.fromCalendarEvent', () {
    test('mappt ein echtes Kalender-Event auf den Feed-Typ', () {
      final event = CalendarEvent(
        id: 'event-1',
        creatorId: 'user-1',
        title: 'Meeting',
        startTime: DateTime.utc(2026, 7, 1, 10),
        endTime: DateTime.utc(2026, 7, 1, 11),
        visibility: 0,
        createdAt: DateTime.utc(2026, 6, 26),
        updatedAt: DateTime.utc(2026, 6, 26),
      );

      final entry = CalendarEntry.fromCalendarEvent(event);

      expect(entry.type, 'calendar_event');
      expect(entry.id, 'event-1');
      expect(entry.title, 'Meeting');
      expect(entry.startTime, DateTime.utc(2026, 7, 1, 10));
      expect(entry.endTime, DateTime.utc(2026, 7, 1, 11));
      expect(entry.allDay, isFalse);
      expect(entry.targetId, 'event-1');
    });
  });
}
