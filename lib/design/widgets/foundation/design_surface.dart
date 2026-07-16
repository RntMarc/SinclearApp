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
    final expanded = _expandToViewport(gradient);
    if (!withGrain) return expanded;
    return GrainOverlay(opacity: tokens.grainOpacity, child: expanded);
  }

  /// Forces the surface to fill the available height when the parent provides
  /// bounded constraints (e.g. a screen body), so the gradient and grain reach
  /// the bottom of the viewport even for short content. Inside a scrolling
  /// parent the height stays content-driven (no finite bound).
  Widget _expandToViewport(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 0.0;
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: child,
        );
      },
    );
  }
}
