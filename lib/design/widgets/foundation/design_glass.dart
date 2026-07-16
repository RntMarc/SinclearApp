import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../theme/design_theme.dart';

/// A frosted-glass panel built from [ClipRRect] + [BackdropFilter].
///
/// Used by glass-first designs (Aurora Glass) and as an optional surface for
/// cards and sheets. The blur stays local to the panel, so it is cheap.
class DesignGlass extends StatelessWidget {
  const DesignGlass({
    this.child,
    this.radius,
    this.padding,
    this.tint,
    this.borderColor,
    super.key,
  });

  final Widget? child;
  final double? radius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final radius = this.radius ?? tokens.radiusLg;
    final effectiveTint = tint ?? tokens.surface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: tokens.glassBlur,
          sigmaY: tokens.glassBlur,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveTint.withValues(alpha: tokens.glassOpacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: (borderColor ?? tokens.border).withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
