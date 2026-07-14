import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Top app bar built entirely from catalog primitives (no Material [AppBar]).
///
/// Shows an optional back action, a title and trailing actions. Renders as a
/// transparent strip – the parent screen should wrap the entire page in a
/// single [DesignSurface] so the gradient is continuous from bar to body.
class DesignAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DesignAppBar({
    this.title,
    this.leading,
    this.actions,
    super.key,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Container(
      height: preferredSize.height,
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg, 0, tokens.spaceLg, tokens.spaceXs,
      ),
      child: SafeArea(
        top: true,
        bottom: false,
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
