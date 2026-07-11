import 'package:flutter/material.dart';

import '../../theme/beyond_theme.dart';
import 'beyond_text.dart';

/// Glass list row used across menus, sheets and settings. Highlights the active
/// entry with a brand-tinted fill and a soft glow.
class BeyondListTile extends StatelessWidget {
  final Widget? leading;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;

  const BeyondListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;

    return Material(
      color: selected
          ? tokens.color.brandBlue.withValues(alpha: 0.16)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(tokens.radius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radius.md),
        splashColor: tokens.color.brandBlue.withValues(alpha: 0.12),
        child: Padding(
          padding:
              contentPadding ?? EdgeInsets.all(tokens.spacing.md),
          child: Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                IconTheme(
                  data: IconThemeData(
                    color: selected
                        ? tokens.color.brandBlue
                        : tokens.color.onSurfaceVariant,
                  ),
                  child: leading!,
                ),
                SizedBox(width: tokens.spacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (title != null)
                      BeyondText(
                        title!,
                        kind: BeyondTextKind.bodyLarge,
                        color: selected
                            ? tokens.color.brandBlue
                            : tokens.color.onSurface,
                      ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      BeyondText(
                        subtitle!,
                        kind: BeyondTextKind.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                SizedBox(width: tokens.spacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
