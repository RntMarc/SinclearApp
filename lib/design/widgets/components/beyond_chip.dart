import 'package:flutter/material.dart';

import '../../effects/beyond_glass.dart';
import '../../theme/beyond_theme.dart';
import 'beyond_text.dart';

/// Small glass pill for tags, statuses and metadata.
class BeyondChip extends StatelessWidget {
  final String label;
  final Widget? icon;
  final Color? color;
  final VoidCallback? onTap;

  const BeyondChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    final tint = color ?? tokens.color.brandBlue;

    final child = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.sm,
        vertical: tokens.spacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            IconTheme(
              data: IconThemeData(size: 14, color: tint),
              child: icon!,
            ),
            SizedBox(width: tokens.spacing.xs),
          ],
          BeyondText(
            label,
            kind: BeyondTextKind.labelSmall,
            color: tint,
          ),
        ],
      ),
    );

    return BeyondGlass(
      borderRadius: BorderRadius.circular(tokens.radius.pill),
      blurSigma: 8,
      padding: EdgeInsets.zero,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(tokens.radius.pill),
              child: child,
            )
          : child,
    );
  }
}

/// Compact count/status badge.
class BeyondBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const BeyondBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    final tint = color ?? tokens.color.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(tokens.radius.pill),
      ),
      child: BeyondText(
        label,
        kind: BeyondTextKind.labelSmall,
        color: Colors.white,
      ),
    );
  }
}
