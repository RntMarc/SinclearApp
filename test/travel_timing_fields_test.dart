import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/travel/widgets/travel_timing_fields.dart';

void main() {
  group('autoEndForStart', () {
    test('getaktet: eine Stunde später', () {
      final end = autoEndForStart(DateTime(2026, 7, 1, 14, 30), allDay: false);
      expect(end, DateTime(2026, 7, 1, 15, 30));
    });

    test('ganztägig: derselbe Tag ohne Uhrzeit', () {
      final end = autoEndForStart(DateTime(2026, 7, 1, 9, 15), allDay: true);
      expect(end, DateTime(2026, 7, 1));
    });
  });
}
