import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/press_scale.dart';

/// A navigation entry (icon + label) with an active highlight. Used in the
/// showcase to demonstrate navigation styling for each design.
class DesignNavItem extends StatelessWidget {
  const DesignNavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final fg = active ? tokens.primary : tokens.textLow;
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceSm,
        ),
        decoration: BoxDecoration(
          color: active ? tokens.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: fg, size: 22),
            SizedBox(width: tokens.spaceSm),
            DesignText(label, style: DesignTextStyle.label, color: fg),
          ],
        ),
      ),
    );
  }
}
