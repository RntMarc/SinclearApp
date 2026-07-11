import 'package:flutter/material.dart';

import '../../effects/beyond_glass.dart';
import '../../effects/beyond_glow.dart';
import '../../effects/beyond_grain.dart';
import '../../theme/beyond_theme.dart';
import '../../tokens/beyond_tokens.dart';
import 'beyond_text.dart';

enum BeyondButtonVariant { primary, glass, ghost }

/// Catalog button. `primary` paints the signature gradient and glows when
/// enabled; `glass` is a frosted panel; `ghost` is a low-emphasis text button.
class BeyondButton extends StatelessWidget {
  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final BeyondButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const BeyondButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.variant = BeyondButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
    this.height,
  });

  bool get _enabled => onPressed != null && !isLoading;

  Widget _content(BuildContext context, {required bool onGradient}) {
    final tokens = context.beyond;
    final color = onGradient ? Colors.white : tokens.color.onSurface;

    if (isLoading) {
      return SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }

    final text = label != null
        ? BeyondText(
            label!,
            kind: BeyondTextKind.label,
            color: color,
          )
        : child;

    if (icon == null) return text ?? const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconTheme(
          data: IconThemeData(color: color, size: 18),
          child: icon!,
        ),
        SizedBox(width: tokens.spacing.sm),
        if (text != null) text,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    final radius = BorderRadius.circular(tokens.radius.pill);
    final h = height ?? 48;
    final pad = padding ??
        EdgeInsets.symmetric(
          horizontal: tokens.spacing.lg,
          vertical: tokens.spacing.sm,
        );

    switch (variant) {
      case BeyondButtonVariant.primary:
        return BeyondGlow(
          active: _enabled,
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              onTap: onPressed,
              borderRadius: radius,
              splashColor: Colors.white.withValues(alpha: 0.2),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    children: <Widget>[
                      Ink(
                        decoration: BoxDecoration(
                          gradient: BeyondBrand.signature,
                          borderRadius: radius,
                        ),
                        child: Container(
                          height: h,
                          width: fullWidth ? double.infinity : null,
                          padding: pad,
                          alignment: Alignment.center,
                          child: _content(context, onGradient: true),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: BeyondGrainTexture(
                            opacity: tokens.grainOpacity,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          ),
        );

      case BeyondButtonVariant.glass:
        return BeyondGlass(
          borderRadius: radius,
          padding: pad,
          glow: _enabled,
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              onTap: onPressed,
              borderRadius: radius,
              child: Container(
                height: h,
                width: fullWidth ? double.infinity : null,
                alignment: Alignment.center,
                child: _content(context, onGradient: false),
              ),
            ),
          ),
        );

      case BeyondButtonVariant.ghost:
        return Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            splashColor: tokens.color.brandBlue.withValues(alpha: 0.15),
            child: Container(
              height: h,
              width: fullWidth ? double.infinity : null,
              padding: pad,
              alignment: Alignment.center,
              child: _content(context, onGradient: false),
            ),
          ),
        );
    }
  }
}
