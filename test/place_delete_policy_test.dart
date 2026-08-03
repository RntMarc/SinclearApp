import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/explore/models/explore_models.dart';

void main() {
  group('canDeleteWithinWindow', () {
    final createdAt = '2026-08-03 12:00:00';
    final createdLocal = DateTime.parse('2026-08-03T12:00:00Z').toLocal();

    test('innerhalb von 30 Minuten ist Löschen erlaubt', () {
      expect(
        canDeleteWithinWindow(
          createdAt,
          now: createdLocal.add(const Duration(minutes: 30)),
        ),
        isTrue,
      );
      expect(
        canDeleteWithinWindow(
          createdAt,
          now: createdLocal.add(const Duration(seconds: 30)),
        ),
        isTrue,
      );
    });

    test('nach 30 Minuten ist Löschen nicht mehr erlaubt', () {
      expect(
        canDeleteWithinWindow(
          createdAt,
          now: createdLocal.add(const Duration(minutes: 31)),
        ),
        isFalse,
      );
    });
  });
}
