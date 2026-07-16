import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Compact status pill, e.g. a "Bald" marker or an unread count.
class DesignBadge extends StatelessWidget {
  const DesignBadge({
    required this.label,
    this.color,
    super.key,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final bg = color ?? tokens.surfaceVariant;
    final textColor = bg.computeLuminance() > 0.5
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFF0F0F0);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
      child: DesignText(
        label,
        style: DesignTextStyle.label,
        color: textColor,
      ),
    );
  }
}
