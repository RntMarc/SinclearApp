import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle,
    this.elevation,
    this.scrolledUnderElevation,
    this.backgroundColor,
    this.foregroundColor,
    this.titleSpacing,
    this.toolbarHeight,
    this.bottomOpacity,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final double? elevation;
  final double? scrolledUnderElevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? titleSpacing;
  final double? toolbarHeight;
  final double? bottomOpacity;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveForegroundColor = foregroundColor ?? theme.colorScheme.onSurface;

    return GlassContainer(
      type: GlassType.appBar,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: toolbarHeight ?? kToolbarHeight,
          child: AppBar(
            title: title,
            actions: actions,
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
            centerTitle: centerTitle ?? true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: effectiveForegroundColor,
            titleSpacing: titleSpacing,
          ),
        ),
      ),
    );
  }
}
