import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// A factory that returns a [Marker] with a pin-badge [child], tip-anchored
/// so that the pin's tip sits exactly on [point].
Marker designMapMarker({
  required LatLng point,
  required IconData icon,
  required Color color,
  double size = 36,
  VoidCallback? onTap,
}) =>
    Marker(
      point: point,
      width: size,
      height: size,
      alignment: Alignment.topCenter,
      child: onTap != null
          ? GestureDetector(
              onTap: onTap,
              child: _PinBadge(icon: icon, color: color, size: size),
            )
          : _PinBadge(icon: icon, color: color, size: size),
    );

/// Geometry of the pin's outline for a badge of [size] pixels.
///
/// The taper sides are tangent to the head circle, so the transition between
/// the circular head and the tip is smooth (no kink or seam).
({Offset center, double radius, Offset leftTangent, Offset rightTangent,
  Offset tip}) pinGeometry(double size) {
  final headSize = size * 0.72;
  final radius = headSize / 2;
  final cx = size / 2;
  final cy = headSize / 2;
  final tip = Offset(cx, size);
  final d = tip.dy - cy;
  final cosPhi = radius / d;
  final sinPhi = math.sqrt(1 - cosPhi * cosPhi);
  return (
    center: Offset(cx, cy),
    radius: radius,
    leftTangent: Offset(cx - radius * sinPhi, cy + radius * cosPhi),
    rightTangent: Offset(cx + radius * sinPhi, cy + radius * cosPhi),
    tip: tip,
  );
}

/// Returns the pin as one closed outline: the head circle's major arc from the
/// left tangent point over the top to the right tangent point, then the two
/// tangent sides down to the tip.
Path buildPinPath(double size) {
  final g = pinGeometry(size);
  final path = Path()..moveTo(g.leftTangent.dx, g.leftTangent.dy);
  final aLeft = math.atan2(
    g.leftTangent.dy - g.center.dy,
    g.leftTangent.dx - g.center.dx,
  );
  final aRight = math.atan2(
    g.rightTangent.dy - g.center.dy,
    g.rightTangent.dx - g.center.dx,
  );
  const segments = 48;
  for (var i = 1; i <= segments; i++) {
    final angle = aLeft + (aRight + 2 * math.pi - aLeft) * i / segments;
    path.lineTo(
      g.center.dx + g.radius * math.cos(angle),
      g.center.dy + g.radius * math.sin(angle),
    );
  }
  path
    ..lineTo(g.tip.dx, g.tip.dy)
    ..close();
  return path;
}

/// A pin-shaped badge: a single solid-filled vector shape with the [icon]
/// centered in its head, so head and tip are one part without a seam.
class _PinBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _PinBadge({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final g = pinGeometry(size);
    final iconSize = size * 0.36;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _PinPainter(color: color, pinSize: size)),
          ),
          Positioned(
            left: g.center.dx - iconSize / 2,
            top: g.center.dy - iconSize / 2,
            width: iconSize,
            height: iconSize,
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ],
      ),
    );
  }
}

/// Draws the pin as a single [buildPinPath] shape with a soft glow behind it.
class _PinPainter extends CustomPainter {
  final Color color;
  final double pinSize;

  _PinPainter({required this.color, required this.pinSize});

  @override
  void paint(Canvas canvas, Size size) {
    final path = buildPinPath(pinSize);

    final glow = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(path, glow);
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PinPainter old) =>
      color != old.color || pinSize != old.pinSize;
}
