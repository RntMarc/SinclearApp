import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/press_scale.dart';

/// A list row composed from catalog primitives: leading, title, subtitle and
/// an optional trailing widget.
class DesignListTile extends StatelessWidget {
  const DesignListTile({
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    super.key,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final tile = Row(
      children: <Widget>[
        if (leading != null) ...<Widget>[
          leading!,
          SizedBox(width: tokens.spaceMd),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DesignText(
                title,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
              if (subtitle != null) ...<Widget>[
                SizedBox(height: tokens.spaceXs),
                DesignText(
                  subtitle!,
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null)
          Padding(
            padding: EdgeInsets.only(left: tokens.spaceMd),
            child: trailing!,
          ),
      ],
    );
    if (onTap == null) return tile;
    return PressScale(onTap: onTap, child: tile);
  }
}
