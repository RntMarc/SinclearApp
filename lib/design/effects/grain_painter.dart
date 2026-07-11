import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Paints a tileable monochrome noise image, used as a film-grain overlay.
///
/// The noise is generated exactly once per [opacity] (cached) and then tiled
/// across the surface via an [ImageShader]. It is intentionally low-opacity
/// and used punctually, never stretched across an entire screen as filler.
class GrainPainter extends CustomPainter {
  const GrainPainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ImageShader(
        image,
        TileMode.repeated,
        TileMode.repeated,
        Matrix4.identity().storage,
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant GrainPainter old) => old.image != image;
}

/// Generates and caches a tileable noise [ui.Image] keyed by its opacity.
class _NoiseCache {
  _NoiseCache._();

  static final _NoiseCache instance = _NoiseCache._();

  final Map<double, ui.Image> _cache = <double, ui.Image>{};

  /// Returns a cached noise image for the given [opacity].
  Future<ui.Image> image(double opacity) async {
    if (_cache.containsKey(opacity)) return _cache[opacity]!;

    const size = 140;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final random = math.Random(1337);
    final paint = Paint();
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final v = random.nextDouble();
        if (v > 0.55) {
          final alpha = (v * opacity * 255).round().clamp(0, 255);
          paint.color = Color.fromARGB(alpha, 255, 255, 255);
          canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
        }
      }
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    _cache[opacity] = img;
    return img;
  }
}

/// A punctual film-grain overlay. Wrap a child to add subtle texture on top of
/// it; for full backgrounds prefer using it on the surface panel only.
class GrainOverlay extends StatefulWidget {
  const GrainOverlay({this.opacity = 0.05, this.child, super.key});

  final double opacity;
  final Widget? child;

  @override
  State<GrainOverlay> createState() => _GrainOverlayState();
}

class _GrainOverlayState extends State<GrainOverlay> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant GrainOverlay old) {
    super.didUpdateWidget(old);
    if (old.opacity != widget.opacity) _load();
  }

  Future<void> _load() async {
    final image = await _NoiseCache.instance.image(widget.opacity);
    if (mounted) setState(() => _image = image);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (widget.child != null) widget.child!,
        if (_image != null)
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: GrainPainter(_image!))),
          ),
      ],
    );
  }
}
