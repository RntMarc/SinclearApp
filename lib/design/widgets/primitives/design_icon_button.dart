import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import 'press_scale.dart';

/// Rounded icon button with springy press feedback.
class DesignIconButton extends StatelessWidget {
  const DesignIconButton({
    required this.icon,
    this.onPressed,
    this.tinted = false,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final bg = tinted ? tokens.primary : tokens.surfaceVariant;
    final fg = tinted ? tokens.textOnPrimary : tokens.textHigh;
    return PressScale(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}
