import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart' as glass_kit;

enum GlassType {
  appBar,
  card,
  bottomNav,
  fab,
  chip,
  bottomSheet,
  dialog,
  navigationBar,
  drawer,
}

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.type = GlassType.card,
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
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double? height;
  final double? width;
  final Gradient? gradient;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;

  GlassConfig get _config {
    switch (type) {
      case GlassType.appBar:
        return GlassConfig(
          blur: 20.0,
          frostedOpacity: 0.15,
          borderRadius: BorderRadius.zero,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
        );
      case GlassType.card:
        return GlassConfig(
          blur: 15.0,
          frostedOpacity: 0.12,
          borderRadius: borderRadius ?? BorderRadius.circular(16.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.08),
            ],
          ),
        );
      case GlassType.bottomNav:
        return GlassConfig(
          blur: 25.0,
          frostedOpacity: 0.18,
          borderRadius: BorderRadius.zero,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
        );
      case GlassType.fab:
        return GlassConfig(
          blur: 12.0,
          frostedOpacity: 0.2,
          borderRadius: borderRadius ?? BorderRadius.circular(16.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.12),
            ],
          ),
        );
      case GlassType.chip:
        return GlassConfig(
          blur: 10.0,
          frostedOpacity: 0.1,
          borderRadius: borderRadius ?? BorderRadius.circular(20.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.08),
            ],
          ),
        );
      case GlassType.bottomSheet:
        return GlassConfig(
          blur: 30.0,
          frostedOpacity: 0.2,
          borderRadius: borderRadius ?? const BorderRadius.vertical(
            top: Radius.circular(24.0),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.22),
              Colors.white.withValues(alpha: 0.12),
            ],
          ),
        );
      case GlassType.dialog:
        return GlassConfig(
          blur: 25.0,
          frostedOpacity: 0.18,
          borderRadius: borderRadius ?? BorderRadius.circular(24.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
        );
      case GlassType.navigationBar:
        return GlassConfig(
          blur: 20.0,
          frostedOpacity: 0.15,
          borderRadius: borderRadius ?? BorderRadius.circular(12.0),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.08),
            ],
          ),
        );
      case GlassType.drawer:
        return GlassConfig(
          blur: 25.0,
          frostedOpacity: 0.2,
          borderRadius: borderRadius ?? BorderRadius.zero,
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final effectiveBorderRadius = borderRadius ?? config.borderRadius;

    Widget glassChild = glass_kit.GlassContainer.frostedGlass(
      height: height,
      width: width,
      blur: config.blur,
      frostedOpacity: config.frostedOpacity,
      borderRadius: effectiveBorderRadius,
      gradient: gradient ?? config.gradient,
      borderColor: borderColor ?? Colors.white.withValues(alpha: 0.2),
      borderWidth: borderWidth ?? 1.0,
      margin: margin,
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      glassChild = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: glassChild,
      );
    }

    return glassChild;
  }
}

class GlassConfig {
  const GlassConfig({
    required this.blur,
    required this.frostedOpacity,
    required this.borderRadius,
    required this.gradient,
  });

  final double blur;
  final double frostedOpacity;
  final BorderRadius borderRadius;
  final Gradient gradient;
}
