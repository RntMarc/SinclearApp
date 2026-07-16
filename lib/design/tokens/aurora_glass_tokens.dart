import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Airy, frosted-glass direction: translucent surfaces, soft mesh gradients
/// and a pronounced blur. Light + dark instances are produced from [brightness].
class AuroraGlassTokens extends DesignTokens {
  const AuroraGlassTokens(super.brightness);

  @override
  Color get background => isDark
      ? const Color(0xFF0B1220)
      : const Color(0xFFEEF3FB);

  @override
  Gradient get backgroundGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0B1220),
            Color(0xFF0E1A33),
            Color(0xFF10162E),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFEEF3FB),
            Color(0xFFE6F0FB),
            Color(0xFFF0ECFB),
          ],
        );

  @override
  Color get surface => isDark
      ? const Color(0xFF1E2A42)
      : const Color(0xFFFFFFFF);

  @override
  Color get surfaceVariant => isDark
      ? const Color(0xFF283650)
      : const Color(0xFFEAF1FC);

  @override
  Color get primary => isDark
      ? const Color(0xFF60A5FA)
      : const Color(0xFF2563EB);

  @override
  Color get onPrimary => const Color(0xFFFFFFFF);

  @override
  Color get secondary => isDark
      ? const Color(0xFF67E8F9)
      : const Color(0xFF06B6D4);

  @override
  Color get onSecondary => isDark
      ? const Color(0xFF04222B)
      : const Color(0xFFFFFFFF);

  @override
  Color get accentA => const Color(0xFF8B5CF6);

  @override
  Color get accentB => const Color(0xFF34D399);

  @override
  Color get textHigh =>
      isDark ? const Color(0xFFEAF1FF) : const Color(0xFF0F172A);

  @override
  Color get textLow =>
      isDark ? const Color(0xFF9FB2CF) : const Color(0xFF64748B);

  @override
  Color get textOnPrimary => const Color(0xFFFFFFFF);

  @override
  Color get border =>
      isDark ? const Color(0xFF3A4B6B) : const Color(0xFFD6E2F5);

  @override
  Color get divider =>
      isDark ? const Color(0xFF243352) : const Color(0xFFE2EAF6);

  @override
  Color get glow => isDark
      ? const Color(0xFF60A5FA)
      : const Color(0xFF2563EB);

  @override
  Color get success => const Color(0xFF22C55E);

  @override
  Color get warning => const Color(0xFFF59E0B);

  @override
  Color get danger => const Color(0xFFEF4444);

  @override
  double get radiusSm => 16;

  @override
  double get radiusMd => 20;

  @override
  double get radiusLg => 24;

  @override
  double get radiusXl => 28;

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
  double get grainOpacity => 0.05;

  @override
  double get glassBlur => 18;

  @override
  double get glassOpacity => 0.70;

  @override
  double get glowBlur => 18;

  @override
  bool get useGlass => true;

  @override
  String get fontFamily => 'Chivo';
}
