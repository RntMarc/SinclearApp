import 'dart:math';
import 'package:flutter/material.dart';

class NoiseOverlay extends StatelessWidget {
  const NoiseOverlay({
    super.key,
    this.opacity = 0.05,
    this.blendMode = BlendMode.overlay,
    this.child,
  });

  final double opacity;
  final BlendMode blendMode;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (child != null) child!,
        Positioned.fill(
          child: CustomPaint(
            painter: _NoisePainter(opacity: opacity, blendMode: blendMode),
          ),
        ),
      ],
    );
  }
}

class NoiseWithChild extends StatelessWidget {
  const NoiseWithChild({
    super.key,
    required this.child,
    this.noiseOpacity = 0.05,
    this.blendMode = BlendMode.overlay,
  });

  final Widget child;
  final double noiseOpacity;
  final BlendMode blendMode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _NoisePainter(
                opacity: noiseOpacity,
                blendMode: blendMode,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoisePainter extends CustomPainter {
  _NoisePainter({
    required this.opacity,
    required this.blendMode,
  });

  final double opacity;
  final BlendMode blendMode;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final pixelSize = 2.0;

    for (double x = 0; x < size.width; x += pixelSize) {
      for (double y = 0; y < size.height; y += pixelSize) {
        final brightness = random.nextDouble();
        final color = Color.fromRGBO(
          (brightness * 255).toInt(),
          (brightness * 255).toInt(),
          (brightness * 255).toInt(),
          opacity,
        );

        final paint = Paint()..color = color;
        canvas.drawRect(
          Rect.fromLTWH(x, y, pixelSize, pixelSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) => false;
}

class NoiseFilter extends StatelessWidget {
  const NoiseFilter({
    super.key,
    required this.child,
    this.intensity = 0.03,
    this.enabled = true,
  });

  final Widget child;
  final double intensity;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: _NoiseTexture(intensity: intensity),
          ),
        ),
      ],
    );
  }
}

class _NoiseTexture extends StatelessWidget {
  const _NoiseTexture({required this.intensity});

  final double intensity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrainPainter(intensity: intensity),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final paint = Paint();

    for (double x = 0; x < size.width; x += 1.0) {
      for (double y = 0; y < size.height; y += 1.0) {
        final noise = random.nextDouble();
        final alpha = (noise * intensity * 255).toInt().clamp(0, 255);

        if (alpha > 0) {
          paint.color = Color.fromRGBO(128, 128, 128, alpha / 255.0);
          canvas.drawRect(
            Rect.fromLTWH(x, y, 1.0, 1.0),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldDelegate) => false;
}
