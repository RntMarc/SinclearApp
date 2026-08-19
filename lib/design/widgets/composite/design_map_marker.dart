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
}) =>
    Marker(
      point: point,
      width: size,
      height: size,
      alignment: Alignment.topCenter,
      child: _PinBadge(icon: icon, color: color, size: size),
    );

/// A pin-shaped badge: a circular head with the [icon] inside and a downward
/// taper whose top edge follows the head's circle, so the two shapes join
/// without a seam; the tip reaches exactly the bottom of the box, letting a
/// `Alignment.topCenter` marker place the tip on the coordinate.
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
    final headSize = size * 0.72;
    final iconSize = size * 0.36;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: headSize,
            height: headSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _TrianglePainter(color: color, badgeSize: size),
            ),
          ),
        ],
      ),
    );
  }
}

/// Geometry of the pin's taper for a badge of [badgeSize] pixels.
///
/// The junction points sit on the head circle (the taper starts where the
/// circle is [radius] wide) and the tip reaches the bottom of the box.
({Offset center, double radius, Offset leftJunction, Offset rightJunction,
  Offset tip}) pinTaperGeometry(double badgeSize) {
  final headSize = badgeSize * 0.72;
  final radius = headSize / 2;
  final cx = badgeSize / 2;
  final cy = headSize / 2;
  final dx = badgeSize * 0.25;
  final dy = math.sqrt(radius * radius - dx * dx);
  return (
    center: Offset(cx, cy),
    radius: radius,
    leftJunction: Offset(cx - dx, cy + dy),
    rightJunction: Offset(cx + dx, cy + dy),
    tip: Offset(cx, badgeSize),
  );
}

/// Returns the pin's taper outline in badge coordinates: a top edge following
/// the head circle's lower arc (sampled) from the left to the right junction
/// point, then the two sides down to a tip at the bottom of the box.
Path buildPinTaperPath(double badgeSize) {
  final g = pinTaperGeometry(badgeSize);
  final path = Path()..moveTo(g.leftJunction.dx, g.leftJunction.dy);
  final aLeft = math.atan2(
    g.leftJunction.dy - g.center.dy,
    g.leftJunction.dx - g.center.dx,
  );
  final aRight = math.atan2(
    g.rightJunction.dy - g.center.dy,
    g.rightJunction.dx - g.center.dx,
  );
  const segments = 32;
  for (var i = 1; i < segments; i++) {
    final angle = aLeft + (aRight - aLeft) * i / segments;
    path.lineTo(
      g.center.dx + g.radius * math.cos(angle),
      g.center.dy + g.radius * math.sin(angle),
    );
  }
  path
    ..lineTo(g.rightJunction.dx, g.rightJunction.dy)
    ..lineTo(g.tip.dx, g.tip.dy)
    ..close();
  return path;
}

/// Draws the pin's taper with [buildPinTaperPath], filling the shape with
/// [color].
class _TrianglePainter extends CustomPainter {
  final Color color;
  final double badgeSize;

  _TrianglePainter({required this.color, required this.badgeSize});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      buildPinTaperPath(badgeSize),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      color != old.color || badgeSize != old.badgeSize;
}
