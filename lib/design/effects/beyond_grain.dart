import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Cached monochrome noise tile. Rendered once into a [ui.Image] and painted
/// via a single tiled [ImageShader] draw call. Shared across all instances so
/// the noise is generated only once per app run.
class _GrainImage {
  static ui.Image? _noise;

  static Future<ui.Image> ensure() async {
    if (_noise != null) return _noise!;
    const size = 140.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final rng = math.Random(1337);
    final paint = ui.Paint();
    for (double y = 0; y < size; y += 1) {
      for (double x = 0; x < size; x += 1) {
        paint.color = Color.fromRGBO(255, 255, 255, rng.nextDouble() * 0.2);
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
      }
    }
    _noise = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    return _noise!;
  }
}

class _GrainPainter extends CustomPainter {
  final ui.Image noise;
  final Color color;
  final double opacity;

  const _GrainPainter(this.noise, this.color, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ImageShader(
        noise,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      )
      ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter old) =>
      old.color != color || old.opacity != opacity;
}

/// Paints the film-grain texture over its own bounds. Use it as an overlay
/// (clipped to the parent's shape) on elements that should feel tactile:
/// gradient buttons, glass panels, gradient backgrounds. The noise tile is
/// generated once and shared across all instances.
class BeyondGrainTexture extends StatefulWidget {
  final double opacity;

  const BeyondGrainTexture({super.key, this.opacity = 0.06});

  @override
  State<BeyondGrainTexture> createState() => _BeyondGrainTextureState();
}

class _BeyondGrainTextureState extends State<BeyondGrainTexture> {
  ui.Image? _noise;

  @override
  void initState() {
    super.initState();
    _GrainImage.ensure().then((image) {
      if (mounted) setState(() => _noise = image);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_noise == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : const Color(0xFF0A1622);

    return RepaintBoundary(
      child: CustomPaint(
        painter: _GrainPainter(_noise!, color, widget.opacity),
        size: Size.infinite,
      ),
    );
  }
}

/// Convenience wrapper that overlays the grain texture on top of [child],
/// filling its bounds. For most cases prefer placing [BeyondGrainTexture]
/// directly inside a clipped [Stack] on the specific element.
class BeyondGrain extends StatelessWidget {
  final Widget child;
  final double opacity;

  const BeyondGrain({
    super.key,
    required this.child,
    this.opacity = 0.06,
  });

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: BeyondGrainTexture(opacity: opacity),
            ),
          ),
        ],
      );
}
