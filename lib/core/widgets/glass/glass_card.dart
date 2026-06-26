import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      type: GlassType.card,
      padding: padding ?? const EdgeInsets.all(16.0),
      margin: margin ?? const EdgeInsets.all(8.0),
      borderRadius: borderRadius,
      onTap: onTap,
      child: child ?? const SizedBox.shrink(),
    );
  }
}
