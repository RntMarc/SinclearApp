import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassBottomSheet extends StatelessWidget {
  const GlassBottomSheet({
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
    bool isScrollControlled = false,
    bool useSafeArea = true,
    bool isDismissible = true,
    bool enableDrag = true,
    bool? showDragHandle,
    Color? barrierColor,
    RouteSettings? routeSettings,
    double? scrollControlDisabledMaxHeightRatio,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle ?? true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: barrierColor ?? Colors.black54,
      routeSettings: routeSettings,
      scrollControlDisabledMaxHeightRatio:
          scrollControlDisabledMaxHeightRatio ?? 0.9,
      builder: (context) => GlassContainer(
        type: GlassType.bottomSheet,
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: builder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      type: GlassType.bottomSheet,
      padding: padding,
      child: SafeArea(
        child: child,
      ),
    );
  }
}
