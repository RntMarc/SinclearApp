import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassFAB extends StatelessWidget {
  const GlassFAB({
    super.key,
    this.onPressed,
    this.child,
    this.tooltip,
    this.heroTag,
    this.mini = false,
  });

  final VoidCallback? onPressed;
  final Widget? child;
  final String? tooltip;
  final Object? heroTag;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GlassContainer(
        type: GlassType.fab,
        borderRadius: mini
            ? BorderRadius.circular(12.0)
            : BorderRadius.circular(16.0),
        onTap: onPressed,
        child: SizedBox(
          width: mini ? 40.0 : 56.0,
          height: mini ? 40.0 : 56.0,
          child: Center(child: child),
        ),
      ),
    );
  }
}
