import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/beyond_theme.dart';
import '../tokens/beyond_tokens.dart';
import 'beyond_grain.dart';

/// Frosted-glass surface. To keep the app fast on mobile, **real blur is opt-in**
/// (`blur: true`) and OFF by default – the "glass" look comes from a translucent
/// fill, a hairline stroke and a soft (or branded) shadow. Use `blur: true`
/// only for a single, small, foreground element (e.g. a hero card), never for
/// lists of panels, the sidebar or the bottom nav.
class BeyondGlass extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool glow;
  final bool brandedBorder;
  final Color? fill;
  final bool blur;
  final double? blurSigma;

  const BeyondGlass({
    super.key,
    this.child,
    this.padding,
    this.borderRadius,
    this.glow = false,
    this.brandedBorder = false,
    this.fill,
    this.blur = false,
    this.blurSigma,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    final radius = borderRadius ?? BorderRadius.circular(tokens.radius.lg);
    final fillColor = fill ?? tokens.color.surfaceGlassFill;

    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: radius,
        border: brandedBorder
            ? null
            : Border.all(color: tokens.color.surfaceGlassStroke, width: 1),
        boxShadow: glow
            ? tokens.glow.brandBoxShadow
            : tokens.glow.softBoxShadow,
      ),
      child: child,
    );

    final grained = ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: <Widget>[
          box,
          Positioned.fill(
            child: IgnorePointer(
              child: BeyondGrainTexture(opacity: tokens.grainOpacity),
            ),
          ),
        ],
      ),
    );

    if (blur) {
      return ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: blurSigma ?? tokens.glass.blurSigma,
            sigmaY: blurSigma ?? tokens.glass.blurSigma,
          ),
          child: grained,
        ),
      );
    }

    if (!brandedBorder) return grained;

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: BeyondBrand.signature,
      ),
      padding: const EdgeInsets.all(1),
      child: grained,
    );
  }
}
