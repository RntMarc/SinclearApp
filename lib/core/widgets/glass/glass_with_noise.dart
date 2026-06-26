import 'package:flutter/material.dart';
import 'glass_container.dart';
import '../noise_overlay_optimized.dart';

class GlassWithNoise extends StatelessWidget {
  const GlassWithNoise({
    super.key,
    required this.child,
    this.type = GlassType.card,
    this.noiseIntensity = 0.04,
    this.enableNoise = true,
    this.padding,
    this.margin,
    this.borderRadius,
    this.height,
    this.width,
    this.gradient,
    this.borderColor,
    this.borderWidth,
    this.onTap,
  });

  final Widget child;
  final GlassType type;
  final double noiseIntensity;
  final bool enableNoise;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double? height;
  final double? width;
  final Gradient? gradient;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NoiseFilterOptimized(
      intensity: noiseIntensity,
      enabled: enableNoise,
      child: GlassContainer(
        type: type,
        padding: padding,
        margin: margin,
        borderRadius: borderRadius,
        height: height,
        width: width,
        gradient: gradient,
        borderColor: borderColor,
        borderWidth: borderWidth,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
