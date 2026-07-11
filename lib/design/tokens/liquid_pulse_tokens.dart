import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Dark, energetic direction inspired by music apps: near-black surfaces,
/// vivid neon gradient glows and strong pill shapes. Light + dark instances
/// are produced from [brightness].
class LiquidPulseTokens extends DesignTokens {
  const LiquidPulseTokens(super.brightness);

  @override
  Color get background => isDark
      ? const Color(0xFF0A0A0F)
      : const Color(0xFFF5F3FF);

  @override
  Gradient get backgroundGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0A0A0F),
            Color(0xFF0F1410),
            Color(0xFF140A18),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF5F3FF),
            Color(0xFFEAFBF0),
            Color(0xFFFDEEFF),
          ],
        );

  @override
  Color get surface => isDark
      ? const Color(0xFF14141C)
      : const Color(0xFFFFFFFF);

  @override
  Color get surfaceVariant => isDark
      ? const Color(0xFF1E1E28)
      : const Color(0xFFF0FFF5);

  @override
  Color get primary => isDark
      ? const Color(0xFF1ED760)
      : const Color(0xFF16A34A);

  @override
  Color get onPrimary => const Color(0xFF04130A);

  @override
  Color get secondary => isDark
      ? const Color(0xFFB14BFF)
      : const Color(0xFF8A2BE2);

  @override
  Color get onSecondary => const Color(0xFFFFFFFF);

  @override
  Color get accentA => const Color(0xFFFF2D55);

  @override
  Color get accentB => const Color(0xFF00C2FF);

  @override
  Color get textHigh =>
      isDark ? const Color(0xFFF5FFF8) : const Color(0xFF08110B);

  @override
  Color get textLow =>
      isDark ? const Color(0xFF9AA89F) : const Color(0xFF5A6B60);

  @override
  Color get textOnPrimary => const Color(0xFF04130A);

  @override
  Color get border =>
      isDark ? const Color(0xFF2A2A36) : const Color(0xFFD6F0DE);

  @override
  Color get divider =>
      isDark ? const Color(0xFF20202C) : const Color(0xFFE6F5EC);

  @override
  Color get glow => isDark
      ? const Color(0xFF1ED760)
      : const Color(0xFF16A34A);

  @override
  Color get success => const Color(0xFF1ED760);

  @override
  Color get warning => const Color(0xFFFBBF24);

  @override
  Color get danger => const Color(0xFFFF2D55);

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
  double get grainOpacity => 0.06;

  @override
  double get glassBlur => 10;

  @override
  double get glowBlur => 32;

  @override
  bool get useGlass => false;

  @override
  String get fontFamily => 'Chivo';
}
