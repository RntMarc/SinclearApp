import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// In-page header that *looks* like an app bar but is not one.
///
/// Unlike [DesignAppBar] this is a plain screen section rendered *below* the
/// global shell app bar. It deliberately avoids [SafeArea] and status-bar
/// insets so it never competes with the real app bar for top spacing. Use it
/// for sub-pages that need a local back control plus a title and actions.
class DesignSubpageHeader extends StatelessWidget {
  const DesignSubpageHeader({
    this.title,
    this.leading,
    this.actions,
    super.key,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg, tokens.spaceMd, tokens.spaceLg, tokens.spaceMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
    );
  }
}
