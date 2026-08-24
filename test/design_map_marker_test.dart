import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sinclear_beyond/design/widgets/composite/design_map_marker.dart';

void main() {
  group('pinGeometry', () {
    const size = 36.0;

    test('tangent points lie on the head circle', () {
      final g = pinGeometry(size);
      expect((g.leftTangent - g.center).distance, closeTo(g.radius, 1e-9));
      expect((g.rightTangent - g.center).distance, closeTo(g.radius, 1e-9));
    });

    test('taper sides are tangent to the circle (no kink)', () {
      final g = pinGeometry(size);
      final toLeft = g.leftTangent - g.center;
      final leftSide = g.tip - g.leftTangent;
      expect(
        toLeft.dx * leftSide.dx + toLeft.dy * leftSide.dy,
        closeTo(0, 1e-6),
      );
      final toRight = g.rightTangent - g.center;
      final rightSide = g.tip - g.rightTangent;
      expect(
        toRight.dx * rightSide.dx + toRight.dy * rightSide.dy,
        closeTo(0, 1e-6),
      );
    });

    test('tip reaches the bottom center of the box', () {
      final g = pinGeometry(size);
      expect(g.tip.dx, closeTo(size / 2, 1e-9));
      expect(g.tip.dy, closeTo(size, 1e-9));
    });

    test('pin path is a single closed contour', () {
      final metrics = buildPinPath(size).computeMetrics().toList();
      expect(metrics.length, 1);
      expect(metrics.single.isClosed, isTrue);
    });
  });

  group('designMapMarker onTap', () {
    testWidgets('marker fires onTap when tapped', (tester) async {
      var tapped = false;
      final marker = designMapMarker(
        point: const LatLng(51.0, 10.0),
        icon: Icons.location_on,
        color: Colors.red,
        onTap: () => tapped = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: marker.child,
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
    });

    testWidgets('marker without onTap has no GestureDetector',
        (tester) async {
      final marker = designMapMarker(
        point: const LatLng(51.0, 10.0),
        icon: Icons.location_on,
        color: Colors.red,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: marker.child,
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}