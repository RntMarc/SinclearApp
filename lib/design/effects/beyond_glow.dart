import 'package:flutter/material.dart';

import '../theme/beyond_theme.dart';

/// Adds a soft drop shadow or, when [active], a brand-colored glow around its
/// child. Used to make interactive elements "lift" on hover/tap/selection.
class BeyondGlow extends StatelessWidget {
  final Widget child;
  final bool active;
  final Color? color;
  final double? blur;

  const BeyondGlow({
    super.key,
    required this.child,
    this.active = false,
    this.color,
    this.blur,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    final shadows = <BoxShadow>[
      if (active || color != null)
        BoxShadow(
          color: (color ?? tokens.color.brandBlue).withValues(alpha: 0.45),
          blurRadius: blur ?? tokens.glow.brandBlur,
          spreadRadius: 0,
        )
      else
        ...tokens.glow.softBoxShadow,
    ];

    return Container(
      decoration: BoxDecoration(boxShadow: shadows),
      child: child,
    );
  }
}
