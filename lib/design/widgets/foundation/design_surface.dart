import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../../effects/grain_painter.dart';

/// The page background for a design. It paints the resolved gradient and adds
/// a punctual film-grain layer on top. Everything sits on top of this surface.
class DesignSurface extends StatelessWidget {
  const DesignSurface({
    this.child,
    this.withGrain = true,
    this.padding,
    super.key,
  });

  final Widget? child;
  final bool withGrain;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final gradient = Container(
      padding: padding,
      decoration: BoxDecoration(gradient: tokens.backgroundGradient),
      child: child,
    );
    if (!withGrain) return gradient;
    return GrainOverlay(opacity: tokens.grainOpacity, child: gradient);
  }
}
