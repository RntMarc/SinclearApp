import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/calendar/models/calendar_models.dart';

Map<String, dynamic> _entry({
  required String type,
  required String id,
  String? title,
  String? timezone,
  String? startAt,
  String? endAt,
  String? startDate,
  String? endDate,
  bool allDay = false,
  Map<String, dynamic> detail = const {},
}) {
  return {
    'type': type,
    'id': id,
    'title': title,
    'timezone': timezone,
    'startAt': startAt,
    'endAt': endAt,
    'startDate': startDate,
    'endDate': endDate,
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
            timezone: 'Europe/Berlin',
            startAt: '2026-07-01T10:00:00+02:00',
            endAt: '2026-07-01T11:00:00+02:00',
            detail: {'description': 'Weekly'},
          ),
          _entry(
            type: 'travel_event',
            id: 'travel-event-1',
            title: 'Konzert',
            timezone: 'Europe/Berlin',
            startAt: '2026-07-02T20:00:00+02:00',
            endAt: '2026-07-02T23:00:00+02:00',
          ),
          _entry(
            type: 'trip',
            id: 'trip-1',
            title: 'Berlin',
            timezone: 'Europe/Berlin',
            startDate: '2026-07-03',
            endDate: '2026-07-06',
            allDay: true,
          ),
          _entry(
            type: 'birthday',
            id: '2026-07-04-user-1',
            title: 'Geburtstag: Max',
            startDate: '2026-07-04',
            endDate: '2026-07-04',
            allDay: true,
            detail: {'userId': 'user-1'},
          ),
          _entry(
            type: 'pt_journey',
            id: 'journey-1',
            title: 'Hamburg → Berlin',
            timezone: 'UTC',
            startAt: '2026-07-05T08:00:00Z',
            endAt: '2026-07-05T10:30:00Z',
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
      expect(event.timezone, 'Europe/Berlin');
      expect(event.startAt, DateTime.utc(2026, 7, 1, 8));
      expect(event.endAt, DateTime.utc(2026, 7, 1, 9));
      expect(event.startDate, isNull);
      expect(event.detail['description'], 'Weekly');

      expect(response.data[2].allDay, isTrue);
      expect(response.data[2].startAt, isNull);
      expect(response.data[2].startDate, DateTime(2026, 7, 3));
      expect(response.data[4].detail['legs'], isEmpty);
    });

    test('nullable Felder werden zu null, allDay defaultet auf false', () {
      final entry = CalendarEntry.fromJson(_entry(type: 'trip', id: 'trip-1'));

      expect(entry.title, isNull);
      expect(entry.startAt, isNull);
      expect(entry.endAt, isNull);
      expect(entry.startDate, isNull);
      expect(entry.timezone, 'UTC');
      expect(entry.allDay, isFalse);
      expect(entry.detail, isEmpty);
    });

    test('sortInstant nutzt den Instant bzw. den zivilen Tagesbeginn', () {
      final timed = CalendarEntry.fromJson(
        _entry(
          type: 'calendar_event',
          id: 'e',
          startAt: '2026-07-01T10:30:00Z',
          endAt: '2026-07-01T11:00:00Z',
        ),
      );
      expect(timed.sortInstant, DateTime.utc(2026, 7, 1, 10, 30));

      final allDay = CalendarEntry.fromJson(
        _entry(
          type: 'trip',
          id: 't',
          startDate: '2026-07-01',
          endDate: '2026-07-03',
          allDay: true,
        ),
      );
      expect(allDay.sortInstant, DateTime(2026, 7, 1));
    });

    test('displayDay ist ganztägig der zivile Tag', () {
      final allDay = CalendarEntry.fromJson(
        _entry(
          type: 'trip',
          id: 't',
          startDate: '2026-07-01',
          endDate: '2026-07-03',
          allDay: true,
        ),
      );
      expect(allDay.displayDay, DateTime(2026, 7, 1));
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

  group('CalendarEvent.fromJson', () {
    test('parst getaktete Events mit Zeitzone und UTC-Instants', () {
      final event = CalendarEvent.fromJson({
        'id': 'event-1',
        'creatorId': 'user-1',
        'title': 'Meeting',
        'allDay': false,
        'timezone': 'Europe/Berlin',
        'startAt': '2026-07-01T10:00:00+02:00',
        'endAt': '2026-07-01T11:00:00+02:00',
        'visibility': 0,
        'createdAt': '2026-06-26T10:00:00Z',
        'updatedAt': '2026-06-26T10:00:00Z',
      });

      expect(event.timezone, 'Europe/Berlin');
      expect(event.startAt, DateTime.utc(2026, 7, 1, 8));
      expect(event.startInstant, DateTime.utc(2026, 7, 1, 8));
      expect(event.endInstant, DateTime.utc(2026, 7, 1, 9));
    });

    test('ganztägig: ziviler Bereich, endInstant = Tagesende', () {
      final event = CalendarEvent.fromJson({
        'id': 'event-2',
        'creatorId': 'user-1',
        'title': 'Feiertag',
        'allDay': true,
        'timezone': 'Europe/Berlin',
        'startDate': '2026-07-01',
        'endDate': '2026-07-02',
        'visibility': 0,
        'createdAt': '2026-06-26T10:00:00Z',
        'updatedAt': '2026-06-26T10:00:00Z',
      });

      expect(event.allDay, isTrue);
      expect(event.startAt, isNull);
      expect(event.startInstant, DateTime(2026, 7, 1));
      expect(event.endInstant, DateTime(2026, 7, 2, 23, 59));
    });

    test('liest das API-TINYINT allDay (0/1) neben bool', () {
      final event = CalendarEvent.fromJson({
        'id': 'event-3',
        'creatorId': 'user-1',
        'title': 'Feiertag',
        'allDay': 1,
        'startDate': '2026-07-01',
        'endDate': '2026-07-01',
        'visibility': 0,
        'createdAt': '2026-06-26T10:00:00Z',
        'updatedAt': '2026-06-26T10:00:00Z',
      });

      expect(event.allDay, isTrue);
    });
  });

  group('CalendarEntry.fromCalendarEvent', () {
    test('mappt ein echtes Kalender-Event auf den Feed-Typ', () {
      final event = CalendarEvent(
        id: 'event-1',
        creatorId: 'user-1',
        title: 'Meeting',
        allDay: false,
        timezone: 'Europe/Berlin',
        startAt: DateTime.utc(2026, 7, 1, 8),
        endAt: DateTime.utc(2026, 7, 1, 9),
        visibility: 0,
        createdAt: DateTime.utc(2026, 6, 26),
        updatedAt: DateTime.utc(2026, 6, 26),
      );

      final entry = CalendarEntry.fromCalendarEvent(event);

      expect(entry.type, 'calendar_event');
      expect(entry.id, 'event-1');
      expect(entry.title, 'Meeting');
      expect(entry.allDay, isFalse);
      expect(entry.timezone, 'Europe/Berlin');
      expect(entry.startAt, DateTime.utc(2026, 7, 1, 8));
      expect(entry.targetId, 'event-1');
    });
  });
}
