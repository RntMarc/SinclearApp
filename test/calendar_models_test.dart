import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/calendar/models/calendar_models.dart';

Map<String, dynamic> _entry({
  required String type,
  required String id,
  String? title,
  String? startDate,
  String? endDate,
  String? startTime,
  String? endTime,
  bool allDay = false,
  Map<String, dynamic> detail = const {},
}) {
  return {
    'type': type,
    'id': id,
    'title': title,
    'startDate': startDate,
    'endDate': endDate,
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
            startDate: '2026-07-01',
            endDate: '2026-07-01',
            startTime: '10:00:00',
            endTime: '11:00:00',
            detail: {'description': 'Weekly'},
          ),
          _entry(
            type: 'travel_event',
            id: 'travel-event-1',
            title: 'Konzert',
            startDate: '2026-07-02',
            endDate: '2026-07-02',
            startTime: '20:00:00',
            endTime: '23:00:00',
          ),
          _entry(
            type: 'trip',
            id: 'trip-1',
            title: 'Berlin',
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
            startDate: '2026-07-05',
            endDate: '2026-07-05',
            startTime: '08:00:00',
            endTime: '10:30:00',
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
      expect(event.startDate, DateTime(2026, 7, 1));
      expect(event.endDate, DateTime(2026, 7, 1));
      expect(event.startTime, const TimeOfDay(hour: 10, minute: 0));
      expect(event.endTime, const TimeOfDay(hour: 11, minute: 0));
      expect(event.detail['description'], 'Weekly');

      expect(response.data[2].allDay, isTrue);
      expect(response.data[2].startTime, isNull);
      expect(response.data[4].detail['legs'], isEmpty);
    });

    test('nullable Felder werden zu null, allDay defaultet auf false', () {
      final entry = CalendarEntry.fromJson(_entry(type: 'trip', id: 'trip-1'));

      expect(entry.title, isNull);
      expect(entry.startDate, isNull);
      expect(entry.endDate, isNull);
      expect(entry.startTime, isNull);
      expect(entry.allDay, isFalse);
      expect(entry.detail, isEmpty);
    });

    test('sortInstant kombiniert Datum und Uhrzeit, ganztägig = Tagesbeginn', () {
      final timed = CalendarEntry.fromJson(
        _entry(
          type: 'calendar_event',
          id: 'e',
          startDate: '2026-07-01',
          endDate: '2026-07-01',
          startTime: '10:30:00',
          endTime: '11:00:00',
        ),
      );
      expect(timed.sortInstant, DateTime(2026, 7, 1, 10, 30));

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
    test('parst Datum, Uhrzeit und allDay', () {
      final event = CalendarEvent.fromJson({
        'id': 'event-1',
        'creatorId': 'user-1',
        'title': 'Meeting',
        'allDay': false,
        'startDate': '2026-07-01',
        'endDate': '2026-07-01',
        'startTime': '10:00:00',
        'endTime': '11:00:00',
        'visibility': 0,
        'createdAt': '2026-06-26 10:00:00',
        'updatedAt': '2026-06-26 10:00:00',
      });

      expect(event.startDate, DateTime(2026, 7, 1));
      expect(event.startTime, const TimeOfDay(hour: 10, minute: 0));
      expect(event.startInstant, DateTime(2026, 7, 1, 10, 0));
      expect(event.endInstant, DateTime(2026, 7, 1, 11, 0));
    });

    test('ganztägig: keine Uhrzeit, endInstant = Tagesende', () {
      final event = CalendarEvent.fromJson({
        'id': 'event-2',
        'creatorId': 'user-1',
        'title': 'Feiertag',
        'allDay': true,
        'startDate': '2026-07-01',
        'endDate': '2026-07-02',
        'visibility': 0,
        'createdAt': '2026-06-26 10:00:00',
        'updatedAt': '2026-06-26 10:00:00',
      });

      expect(event.allDay, isTrue);
      expect(event.startTime, isNull);
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
        'createdAt': '2026-06-26 10:00:00',
        'updatedAt': '2026-06-26 10:00:00',
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
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 1),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        visibility: 0,
        createdAt: DateTime.utc(2026, 6, 26),
        updatedAt: DateTime.utc(2026, 6, 26),
      );

      final entry = CalendarEntry.fromCalendarEvent(event);

      expect(entry.type, 'calendar_event');
      expect(entry.id, 'event-1');
      expect(entry.title, 'Meeting');
      expect(entry.allDay, isFalse);
      expect(entry.startDate, DateTime(2026, 7, 1));
      expect(entry.startTime, const TimeOfDay(hour: 10, minute: 0));
      expect(entry.targetId, 'event-1');
    });
  });
}
