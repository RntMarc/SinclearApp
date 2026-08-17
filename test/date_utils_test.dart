import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/utils/date_utils.dart';

void main() {
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

  group('daysBetween', () {
    test('DST-übergreifend exakt', () {
      expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
      expect(daysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 26)), 2);
    });

    test('Vergangenheit negativ', () {
      expect(daysBetween(DateTime(2026, 8, 17), DateTime(2026, 8, 16)), -1);
    });
  });
}