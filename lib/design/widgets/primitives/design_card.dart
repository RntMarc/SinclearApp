import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_glass.dart';
import 'press_scale.dart';

/// Raised surface container. Glass-first designs render it as a frosted panel,
/// others as a solid surface with a soft shadow. Builds on [DesignGlass].
class DesignCard extends StatelessWidget {
  const DesignCard({
    this.child,
    this.padding,
    this.onTap,
    this.useGlass,
    super.key,
  });

  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool? useGlass;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final glass = useGlass ?? tokens.useGlass;
    final inner = Padding(
      padding: padding ?? EdgeInsets.all(tokens.spaceLg),
      child: child,
    );

    if (glass) {
      return DesignGlass(child: inner);
    }
    final surface = Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
        boxShadow: tokens.surfaceShadow,
      ),
      child: inner,
    );
    if (onTap == null) return surface;
    return PressScale(onTap: onTap, child: surface);
  }
}
