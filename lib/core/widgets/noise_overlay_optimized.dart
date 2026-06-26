import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class NoiseGenerator {
  static ui.Image? _cachedNoiseImage;
  static const int _noiseSize = 256;

  static Future<ui.Image> getNoiseImage() async {
    if (_cachedNoiseImage != null) return _cachedNoiseImage!;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final random = Random();

    for (int x = 0; x < _noiseSize; x++) {
      for (int y = 0; y < _noiseSize; y++) {
        final brightness = random.nextInt(256);
        final paint = Paint()
          ..color = Color.fromRGBO(brightness, brightness, brightness, 1.0);
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1.0, 1.0),
          paint,
        );
      }
    }

    final picture = recorder.endRecording();
    _cachedNoiseImage = await picture.toImage(_noiseSize, _noiseSize);
    return _cachedNoiseImage!;
  }

  static void clearCache() {
    _cachedNoiseImage?.dispose();
    _cachedNoiseImage = null;
  }
}

class NoiseOverlayOptimized extends StatelessWidget {
  const NoiseOverlayOptimized({
    super.key,
    this.opacity = 0.04,
    this.blendMode = BlendMode.overlay,
    this.child,
  });

  final double opacity;
  final BlendMode blendMode;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: NoiseGenerator.getNoiseImage(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return child ?? const SizedBox.shrink();

        return Stack(
          children: [
            if (child != null) child!,
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: RawImage(
                    image: snapshot.data,
                    fit: BoxFit.cover,
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class NoiseFilterOptimized extends StatelessWidget {
  const NoiseFilterOptimized({
    super.key,
    required this.child,
    this.intensity = 0.04,
    this.enabled = true,
  });

  final Widget child;
  final double intensity;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return FutureBuilder<ui.Image>(
      future: NoiseGenerator.getNoiseImage(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return child;

        return Stack(
          children: [
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: intensity,
                  child: RawImage(
                    image: snapshot.data,
                    fit: BoxFit.cover,
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
