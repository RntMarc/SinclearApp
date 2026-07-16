import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import 'press_scale.dart';

/// Draws a repeating wave pattern, used as a decorative texture on the
/// `patterned` button variant (Wellen-Muster).
class _WavePatternPainter extends CustomPainter {
  const _WavePatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const amplitude = 6.0;
    const wavelength = 22.0;
    for (var row = 0; row < 3; row++) {
      final baseY = size.height * (0.35 + row * 0.18);
      final path = Path();
      path.moveTo(0, baseY);
      for (var x = 0; x <= size.width; x++) {
        final y = baseY +
            amplitude * math.sin(x / wavelength * 2 * 3.14159);
        path.lineTo(x.toDouble(), y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePatternPainter old) =>
      old.color != color;
}

/// Visual variants for [DesignButton].
enum DesignButtonVariant { filled, outlined, ghost, patterned, text }

/// The catalog button. All variants inherit the same shape/layout from this
/// single widget and only differ in how they read the [DesignTokens].
class DesignButton extends StatelessWidget {
  const DesignButton({
    required this.label,
    this.onPressed,
    this.variant = DesignButtonVariant.filled,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final DesignButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final radius = tokens.radiusPill;
    final enabled = onPressed != null && !loading;

    final contentPadding = variant == DesignButtonVariant.text
        ? EdgeInsets.symmetric(
            horizontal: tokens.spaceXs,
            vertical: tokens.spaceXs,
          )
        : EdgeInsets.symmetric(
            horizontal: tokens.spaceXl,
            vertical: tokens.spaceMd,
          );

    final Widget leading = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _textColor(tokens),
            ),
          )
        : (icon != null
            ? Row(
                children: <Widget>[
                  Icon(icon, size: 18),
                  SizedBox(width: tokens.spaceSm),
                ],
              )
            : const SizedBox.shrink());

    Widget content = Container(
      padding: contentPadding,
      decoration: _decoration(tokens, enabled),
      child: DefaultTextStyle(
        style: tokens.labelStyle(tokens.textOnPrimary),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            leading,
            DesignText(
              label,
              style: DesignTextStyle.label,
              color: _textColor(tokens),
            ),
          ],
        ),
      ),
    );

    if (variant == DesignButtonVariant.patterned) {
      content = Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: CustomPaint(
                  painter: _WavePatternPainter(
                    tokens.accentA.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
          content,
        ],
      );
    }

    final button = PressScale(
      onTap: enabled ? onPressed : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  BoxDecoration _decoration(DesignTokens tokens, bool enabled) {
    switch (variant) {
      case DesignButtonVariant.filled:
        return BoxDecoration(
          color: enabled ? tokens.primary : tokens.surfaceVariant,
          borderRadius: BorderRadius.circular(tokens.radiusPill),
          boxShadow: enabled ? tokens.glowShadow : null,
        );
      case DesignButtonVariant.patterned:
        return BoxDecoration(
          color: enabled ? tokens.primary : tokens.surfaceVariant,
          borderRadius: BorderRadius.circular(tokens.radiusPill),
          boxShadow: enabled ? tokens.glowShadow : null,
        );
      case DesignButtonVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.radiusPill),
          border: Border.all(color: tokens.primary, width: 1.5),
        );
      case DesignButtonVariant.ghost:
        return BoxDecoration(
          color: tokens.surfaceVariant.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(tokens.radiusPill),
        );
      case DesignButtonVariant.text:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.radiusPill),
        );
    }
  }

  Color _textColor(DesignTokens tokens) {
    if (!tokens.isDark && variant == DesignButtonVariant.outlined) {
      return tokens.primary;
    }
    switch (variant) {
      case DesignButtonVariant.filled:
      case DesignButtonVariant.patterned:
        return tokens.textOnPrimary;
      case DesignButtonVariant.outlined:
      case DesignButtonVariant.ghost:
      case DesignButtonVariant.text:
        return tokens.primary;
    }
  }
}
