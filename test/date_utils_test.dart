import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/utils/date_utils.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);
  group('formatDuration', () {
    test('Jahre, Monate und Tage', () {
      expect(
        formatDuration(DateTime(2023, 2, 5), DateTime(2026, 8, 17)),
        'Seit 3 Jahren 6 Monaten und 12 Tagen',
      );
    });

    test('Wochen und Tage statt Monaten', () {
      expect(
        formatDuration(DateTime(2026, 8, 2), DateTime(2026, 8, 17)),
        'Seit 2 Wochen und 1 Tag',
      );
    });

    test('nur Tage', () {
      expect(
        formatDuration(DateTime(2026, 8, 16), DateTime(2026, 8, 17)),
        'Seit 1 Tag',
      );
      expect(
        formatDuration(DateTime(2026, 8, 11), DateTime(2026, 8, 17)),
        'Seit 6 Tagen',
      );
    });

    test('nur Jahre und Singularformen', () {
      expect(
        formatDuration(DateTime(2025, 8, 17), DateTime(2026, 8, 17)),
        'Seit 1 Jahr',
      );
    });

    test('vordere Nullen weglassen', () {
      expect(
        formatDuration(DateTime(2026, 8, 14), DateTime(2026, 8, 17)),
        'Seit 3 Tagen',
      );
      expect(
        formatDuration(DateTime(2026, 1, 1), DateTime(2026, 8, 17)),
        'Seit 7 Monaten und 16 Tagen',
      );
    });

    test('gleicher Tag oder Vergangenheit', () {
      final now = DateTime(2026, 8, 17);
      expect(formatDuration(now, now), 'Seit heute');
      expect(formatDuration(DateTime(2026, 8, 18), now), 'Seit heute');
    });

    test('Monatsübergang', () {
      expect(
        formatDuration(DateTime(2026, 6, 28), DateTime(2026, 8, 17)),
        'Seit 1 Monat und 20 Tagen',
      );
    });
  });

  group('nextBirthday', () {
    test('später im Jahr', () {
      expect(
        nextBirthday(DateTime(1994, 3, 15), DateTime(2026, 8, 17)),
        DateTime(2027, 3, 15),
      );
    });

    test('heute Geburtstag', () {
      expect(
        nextBirthday(DateTime(1994, 3, 15), DateTime(2026, 3, 15)),
        DateTime(2026, 3, 15),
      );
    });

    test('bereits vergangen', () {
      expect(
        nextBirthday(DateTime(1994, 3, 15), DateTime(2026, 3, 14)),
        DateTime(2026, 3, 15),
      );
    });

    test('29. Februar in Nicht-Schaltjahren', () {
      expect(
        nextBirthday(DateTime(2000, 2, 29), DateTime(2026, 8, 17)),
        DateTime(2027, 3, 1),
      );
      expect(
        nextBirthday(DateTime(2000, 2, 29), DateTime(2028, 1, 1)),
        DateTime(2028, 2, 29),
      );
    });
  });

  group('ageInYears', () {
    test('Geburtstag noch nicht erreicht', () {
      expect(ageInYears(DateTime(1994, 3, 15), DateTime(2026, 3, 14)), 31);
    });

    test('Geburtstag erreicht', () {
      expect(ageInYears(DateTime(1994, 3, 15), DateTime(2026, 3, 15)), 32);
      expect(ageInYears(DateTime(1994, 3, 15), DateTime(2026, 8, 17)), 32);
    });
  });

  group('formatRelativeDayTime', () {
    late DateTime now;
    late DateTime today;

    setUp(() {
      now = DateTime.now();
      today = DateTime(now.year, now.month, now.day);
    });

    test('gleicher Tag', () {
      final iso = toApiDate(today.add(const Duration(hours: 10, minutes: 30)));
      expect(formatRelativeDayTime(iso), 'Heute, 10:30');
    });

    test('Gestern', () {
      final iso = toApiDate(
        today.subtract(const Duration(days: 1)).add(
          const Duration(hours: 9, minutes: 15),
        ),
      );
      expect(formatRelativeDayTime(iso), 'Gestern, 09:15');
    });

    test('Vorgestern', () {
      final iso = toApiDate(
        today.subtract(const Duration(days: 2)).add(
          const Duration(hours: 18, minutes: 40),
        ),
      );
      expect(formatRelativeDayTime(iso), 'Vorgestern, 18:40');
    });

    test('Vor 3–6 Tagen', () {
      final iso3 = toApiDate(
        today.subtract(const Duration(days: 3)).add(
          const Duration(hours: 11, minutes: 22),
        ),
      );
      expect(formatRelativeDayTime(iso3), 'Vor 3 Tagen, 11:22');

      final iso5 = toApiDate(
        today.subtract(const Duration(days: 5)).add(
          const Duration(hours: 7, minutes: 5),
        ),
      );
      expect(formatRelativeDayTime(iso5), 'Vor 5 Tagen, 07:05');
    });

    test('Ab 7 Tagen absolutes Datum', () {
      final iso = toApiDate(
        today.subtract(const Duration(days: 7)).add(
          const Duration(hours: 14, minutes: 0),
        ),
      );
      expect(formatRelativeDayTime(iso), '${formatDate(parseApiDate(iso))}, 14:00');
    });
  });

  group('daysBetween', () {
    test('DST-übergreifend exakt', () {
      expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
      expect(daysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 26)), 2);
    });

    test('Vergangenheit negativ', () {
      expect(daysBetween(DateTime(2026, 8, 17), DateTime(2026, 8, 16)), -1);
    });
  });

  group('Datum-only- und Uhrzeit-Helfer', () {
    test('toApiDateOnly nutzt das lokale Datum (kein UTC-Shift)', () {
      expect(toApiDateOnly(DateTime(2026, 7, 1, 23, 30)), '2026-07-01');
      expect(toApiDateOnly(DateTime(2026, 7, 1, 0, 5)), '2026-07-01');
    });

    test('parseApiDateOnly behält den zivilen Tag (kein UTC-Shift)', () {
      expect(parseApiDateOnly('2026-07-01'), DateTime(2026, 7, 1));
    });

    test('parseApiTime liest HH:MM:SS und leere Werte', () {
      expect(parseApiTime('10:30:00'), const TimeOfDay(hour: 10, minute: 30));
      expect(parseApiTime(''), isNull);
      expect(parseApiTime(null), isNull);
      expect(parseApiTime('quatsch'), isNull);
    });

    test('toApiTime formatiert HH:MM:SS', () {
      expect(toApiTime(const TimeOfDay(hour: 9, minute: 5)), '09:05:00');
    });

    test('combineDateAndTime: ganztägig = Tagesgrenzen', () {
      final d = DateTime(2026, 7, 1);
      expect(combineDateAndTime(d, null), DateTime(2026, 7, 1));
      expect(
        combineDateAndTime(d, null, endOfDay: true),
        DateTime(2026, 7, 1, 23, 59),
      );
      expect(
        combineDateAndTime(d, const TimeOfDay(hour: 10, minute: 30)),
        DateTime(2026, 7, 1, 10, 30),
      );
    });

    test('formatDayRange eintägig und mehrtägig', () {
      expect(
        formatDayRange(DateTime(2026, 7, 1), DateTime(2026, 7, 1)),
        '01.07.2026',
      );
      expect(
        formatDayRange(DateTime(2026, 7, 1), DateTime(2026, 7, 3)),
        '01.07.2026 – 03.07.2026',
      );
    });
  });

  group('Zeitzonen-Helfer', () {
    test('parseApiInstant liest Offset und Z als UTC-Instant', () {
      expect(
        parseApiInstant('2026-07-01T10:00:00+02:00'),
        DateTime.utc(2026, 7, 1, 8),
      );
      expect(
        parseApiInstant('2026-07-01T10:00:00Z'),
        DateTime.utc(2026, 7, 1, 10),
      );
    });

    test('toApiInstant formatiert mit Offset der Zielzeitzone', () {
      expect(
        toApiInstant(DateTime.utc(2026, 7, 1, 8), 'Europe/Berlin'),
        '2026-07-01T10:00:00+02:00',
      );
      expect(
        toApiInstant(DateTime.utc(2026, 1, 1, 8), 'Europe/Berlin'),
        '2026-01-01T09:00:00+01:00',
      );
      expect(
        toApiInstant(DateTime.utc(2026, 7, 1, 8), 'UTC'),
        '2026-07-01T08:00:00Z',
      );
    });

    test('wallTimeToInstant berücksichtigt Sommer-/Winterzeit', () {
      expect(
        wallTimeToInstant(DateTime(2026, 7, 1, 10), 'Europe/Berlin'),
        DateTime.utc(2026, 7, 1, 8),
      );
      expect(
        wallTimeToInstant(DateTime(2026, 1, 1, 10), 'Europe/Berlin'),
        DateTime.utc(2026, 1, 1, 9),
      );
    });

    test('instantToWallTime liefert die Wandzeit der Zone', () {
      expect(
        instantToWallTime(DateTime.utc(2026, 7, 1, 8), 'Europe/Berlin'),
        DateTime(2026, 7, 1, 10),
      );
      expect(
        instantToWallTime(DateTime.utc(2026, 7, 1, 8), 'America/New_York'),
        DateTime(2026, 7, 1, 4),
      );
    });

    test('formatTimeInZone und formatDateTimeInZone', () {
      final instant = DateTime.utc(2026, 7, 1, 8);
      expect(formatTimeInZone(instant, 'Europe/Berlin'), '10:00');
      expect(formatDateTimeInZone(instant, 'Europe/Berlin'), '01.07.2026 10:00');
    });

    test('formatInstantRangeInZone eintägig und mehrtägig', () {
      expect(
        formatInstantRangeInZone(
          DateTime.utc(2026, 7, 1, 8),
          DateTime.utc(2026, 7, 1, 9, 30),
          'Europe/Berlin',
        ),
        '01.07.2026 10:00 – 11:30',
      );
      expect(
        formatInstantRangeInZone(
          DateTime.utc(2026, 7, 1, 8),
          DateTime.utc(2026, 7, 2, 9),
          'Europe/Berlin',
        ),
        '01.07.2026 10:00 – 02.07.2026 11:00',
      );
    });

    test('resolveTimeZone fällt bei unbekannter Zone auf UTC zurück', () {
      expect(
        wallTimeToInstant(DateTime(2026, 7, 1, 10), 'Nonsense/Zone'),
        DateTime.utc(2026, 7, 1, 10),
      );
      expect(
        wallTimeToInstant(DateTime(2026, 7, 1, 10), null),
        DateTime.utc(2026, 7, 1, 10),
      );
    });
  });
}