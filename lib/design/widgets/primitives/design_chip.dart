import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import 'press_scale.dart';

/// Small pill label used for tags, categories and status markers.
class DesignChip extends StatelessWidget {
  const DesignChip({
    required this.label,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final bg = selected ? tokens.primary : tokens.surfaceVariant;
    final fg = selected ? tokens.textOnPrimary : tokens.textLow;
    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd,
        vertical: tokens.spaceXs + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: selected
            ? null
            : Border.all(color: tokens.border.withValues(alpha: 0.6)),
      ),
      child: DesignText(label, style: DesignTextStyle.label, color: fg),
    );
    if (onTap == null) return chip;
    return PressScale(onTap: onTap, child: chip);
  }
}
