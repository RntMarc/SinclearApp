import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_surface.dart';
import '../foundation/design_text.dart';

/// Top app bar built entirely from catalog primitives (no Material [AppBar]).
///
/// Shows an optional back action, a title and trailing actions, sitting on a
/// gradient + grain strip that matches the active design.
class DesignAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DesignAppBar({
    this.title,
    this.leading,
    this.actions,
    this.useGrain = true,
    super.key,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool useGrain;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      withGrain: useGrain,
      child: Container(
        height: preferredSize.height,
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
        child: Row(
          children: <Widget>[
            if (leading != null)
              Padding(
                padding: EdgeInsets.only(right: tokens.spaceSm),
                child: leading!,
              ),
            if (title != null) ...<Widget>[
              if (leading != null) SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignText(
                  title!,
                  style: DesignTextStyle.title,
                  color: tokens.textHigh,
                ),
              ),
            ] else
              const Spacer(),
            if (actions != null)
              ...actions!.map(
                (a) => Padding(
                  padding: EdgeInsets.only(left: tokens.spaceSm),
                  child: a,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
