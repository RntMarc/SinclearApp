import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Playful, expressive direction: squircle shapes, pastel gradients and a
/// springy feel. Light + dark instances are produced from [brightness].
class MateriaPopTokens extends DesignTokens {
  const MateriaPopTokens(super.brightness);

  @override
  Color get background => isDark
      ? const Color(0xFF1A0F2E)
      : const Color(0xFFFDF2F8);

  @override
  Gradient get backgroundGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1A0F2E),
            Color(0xFF2A1850),
            Color(0xFF3B1E63),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFDF2F8),
            Color(0xFFF3E8FF),
            Color(0xFFE0F2FE),
          ],
        );

  @override
  Color get surface => isDark
      ? const Color(0xFF251640)
      : const Color(0xFFFFFFFF);

  @override
  Color get surfaceVariant => isDark
      ? const Color(0xFF321F54)
      : const Color(0xFFF6ECFF);

  @override
  Color get primary => isDark
      ? const Color(0xFFA78BFA)
      : const Color(0xFF7C3AED);

  @override
  Color get onPrimary => isDark
      ? const Color(0xFF1A0F2E)
      : const Color(0xFFFFFFFF);

  @override
  Color get secondary => isDark
      ? const Color(0xFFF0A6D4)
      : const Color(0xFFF472B6);

  @override
  Color get onSecondary => isDark
      ? const Color(0xFF2A0F22)
      : const Color(0xFFFFFFFF);

  @override
  Color get accentA => const Color(0xFF22D3EE);

  @override
  Color get accentB => const Color(0xFFFBBF24);

  @override
  Color get textHigh =>
      isDark ? const Color(0xFFF3EEFF) : const Color(0xFF1F1147);

  @override
  Color get textLow =>
      isDark ? const Color(0xFFB6A8D6) : const Color(0xFF6B6380);

  @override
  Color get textOnPrimary =>
      isDark ? const Color(0xFF1A0F2E) : const Color(0xFFFFFFFF);

  @override
  Color get border =>
      isDark ? const Color(0xFF4B3578) : const Color(0xFFE9D5F2);

  @override
  Color get divider =>
      isDark ? const Color(0xFF3A2860) : const Color(0xFFF0E2F5);

  @override
  Color get glow => isDark
      ? const Color(0xFFA78BFA)
      : const Color(0xFF7C3AED);

  @override
  Color get success => const Color(0xFF22C55E);

  @override
  Color get warning => const Color(0xFFF59E0B);

  @override
  Color get danger => const Color(0xFFEF4444);

  @override
  double get radiusSm => 14;

  @override
  double get radiusMd => 20;

  @override
  double get radiusLg => 26;

  @override
  double get radiusXl => 30;

  @override
  double get radiusPill => 999;

  @override
  double get spaceXs => 4;

  @override
  double get spaceSm => 8;

  @override
  double get spaceMd => 12;

  @override
  double get spaceLg => 16;

  @override
  double get spaceXl => 24;

  @override
  double get spaceXxl => 32;

  @override
  double get grainOpacity => 0.04;

  @override
  double get glassBlur => 6;

  @override
  double get glowBlur => 26;

  @override
  bool get useGlass => false;

  @override
  String get fontFamily => 'Chivo';
}
