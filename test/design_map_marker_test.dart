import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/widgets/composite/design_map_marker.dart';

void main() {
  group('pinTaperGeometry', () {
    const badgeSize = 36.0;

    test('junction points lie exactly on the head circle', () {
      final g = pinTaperGeometry(badgeSize);
      expect((g.leftJunction - g.center).distance, closeTo(g.radius, 1e-9));
      expect((g.rightJunction - g.center).distance, closeTo(g.radius, 1e-9));
      expect(g.leftJunction.dy, closeTo(g.rightJunction.dy, 1e-9));
      expect(g.leftJunction.dx, lessThan(g.center.dx));
      expect(g.rightJunction.dx, greaterThan(g.center.dx));
      expect(g.leftJunction.dy, greaterThan(g.center.dy));
    });

    test('tip reaches the bottom center of the box', () {
      final g = pinTaperGeometry(badgeSize);
      expect(g.tip.dx, closeTo(badgeSize / 2, 1e-9));
      expect(g.tip.dy, closeTo(badgeSize, 1e-9));
    });

    test('taper path is closed and ends on the tip', () {
      final path = buildPinTaperPath(badgeSize);
      expect(path.computeMetrics().first.isClosed, isTrue);
    });
  });
}