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

/// A small pin-shaped badge: a circular head with the [icon] inside and a
/// downward triangle tip whose point reaches exactly the bottom of the box,
/// so a `Alignment.topCenter` marker places the tip on the coordinate.
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
    final tipWidth = size * 0.5;
    final tipHeight = size - headSize;
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
          Positioned(
            top: headSize - tipHeight * 0.2,
            left: (size - tipWidth) / 2,
            child: CustomPaint(
              size: Size(tipWidth, tipHeight),
              painter: _TrianglePainter(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a downward-pointing triangle.
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => color != old.color;
}
