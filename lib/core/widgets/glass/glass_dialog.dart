import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget builder,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
  }) {
    return showGeneralDialog<T>(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) =>
          GlassContainer(
            type: GlassType.dialog,
            padding: const EdgeInsets.all(24.0),
            child: builder,
          ),
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      type: GlassType.dialog,
      padding: padding ?? const EdgeInsets.all(24.0),
      child: child,
    );
  }
}
