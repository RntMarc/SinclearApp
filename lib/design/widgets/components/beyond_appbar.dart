import 'package:flutter/material.dart';

import 'beyond_text.dart';

/// Transparent app bar that renders its title with the brand type scale. Use in
/// combination with [BeyondScaffold] so the surface glow shows behind it.
class BeyondAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final double height;

  const BeyondAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.height = kToolbarHeight,
  }) : assert(title != null || titleText != null,
            'Provide either title or titleText');

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: leading,
        title: title ??
            BeyondTitle(
              titleText!,
              brandGradient: true,
            ),
        actions: actions,
        centerTitle: centerTitle,
      );
}
