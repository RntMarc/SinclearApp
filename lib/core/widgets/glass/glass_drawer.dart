import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassDrawer extends StatelessWidget {
  const GlassDrawer({
    super.key,
    this.child,
    this.padding,
    this.width,
  });

  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      type: GlassType.drawer,
      width: width ?? 304.0,
      padding: padding ?? const EdgeInsets.all(16.0),
      child: SafeArea(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
