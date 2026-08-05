import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Warm, golden direction: amber primary, rich gradients and a luxurious
/// feel. Light + dark instances are produced from [brightness].
class SolsticeTokens extends DesignTokens {
  const SolsticeTokens(super.brightness);

  @override
  Color get background => isDark
      ? const Color(0xFF1A1408)
      : const Color(0xFFFFF8EE);

  @override
  Gradient get backgroundGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1A1408),
            Color(0xFF231A0C),
            Color(0xFF2C1F0E),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFF8EE),
            Color(0xFFFFF3E0),
            Color(0xFFFFECB3),
          ],
        );

  @override
  Color get surface => isDark
      ? const Color(0xFF2A2010)
      : const Color(0xFFFFFFFF);

  @override
  Color get surfaceVariant => isDark
      ? const Color(0xFF3A2E18)
      : const Color(0xFFFFF3E0);

  @override
  Color get primary => isDark
      ? const Color(0xFFFFCA28)
      : const Color(0xFFF57C00);

  @override
  Color get onPrimary => isDark
      ? const Color(0xFF1A1408)
      : const Color(0xFFFFFFFF);

  @override
  Color get secondary => isDark
      ? const Color(0xFFFFAB40)
      : const Color(0xFFFF8F00);

  @override
  Color get onSecondary => const Color(0xFFFFFFFF);

  @override
  Color get accentA => const Color(0xFFFF7043);

  @override
  Color get accentB => const Color(0xFF26A69A);

  @override
  Color get textHigh =>
      isDark ? const Color(0xFFFFF3E0) : const Color(0xFF3E2723);

  @override
  Color get textLow =>
      isDark ? const Color(0xFFBCA88A) : const Color(0xFF8D6E63);

  @override
  Color get textOnPrimary =>
      isDark ? const Color(0xFF1A1408) : const Color(0xFFFFFFFF);

  @override
  Color get border =>
      isDark ? const Color(0xFF4A3A20) : const Color(0xFFFFE0B2);

  @override
  Color get divider =>
      isDark ? const Color(0xFF332810) : const Color(0xFFFFF0D6);

  @override
  Color get glow => isDark
      ? const Color(0xFFFFCA28)
      : const Color(0xFFF57C00);

  @override
  Color get success => const Color(0xFF66BB6A);

  @override
  Color get warning => const Color(0xFFFFCA28);

  @override
  Color get danger => const Color(0xFFEF5350);

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
  double get glassBlur => 8;

  @override
  double get glowBlur => 28;

  @override
  bool get useGlass => false;

  @override
  String get fontFamily => 'Chivo';
}
