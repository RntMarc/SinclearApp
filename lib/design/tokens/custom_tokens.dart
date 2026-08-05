import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// User-defined accent color direction. Takes an arbitrary [accent] color and
/// derives a full token set. Neutral backgrounds and surfaces are kept
/// consistent so the accent stands out.
///
/// A lightweight contrast check is included: combinations that fall below a
/// ratio of 1.5 : 1 are considered "completely unreadable" and blocked.
/// Everything above that threshold is accepted — even hard-to-read pairings
/// are the user's explicit choice.
class CustomTokens extends DesignTokens {
  const CustomTokens(this.accent, super.brightness);

  /// The user-chosen accent color.
  final Color accent;

  // ---------------------------------------------------------------------------
  // Contrast utilities
  // ---------------------------------------------------------------------------

  /// Relative luminance per WCAG 2.x.
  static double _luminance(Color c) => c.computeLuminance();

  /// Contrast ratio between two colors (1 : 1 … 21 : 1).
  static double contrastRatio(Color a, Color b) {
    final l1 = _luminance(a);
    final l2 = _luminance(b);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Threshold below which a pairing is considered completely unreadable.
  static const double blockThreshold = 1.5;

  /// Returns `true` when [foreground] on [background] is completely unreadable.
  static bool isBlocked(Color foreground, Color background) =>
      contrastRatio(foreground, background) < blockThreshold;

  /// Picks black or white so [color] on the result has maximum contrast.
  static Color bestOnColor(Color color) =>
      _luminance(color) > 0.5 ? const Color(0xFF1A1A2E) : Colors.white;

  /// Slightly desaturated variant of [color] for secondary elements.
  static Color _desaturated(Color color, {double factor = 0.6}) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withSaturation(hsl.saturation * factor).toColor();
  }

  // ---------------------------------------------------------------------------
  // Token overrides
  // ---------------------------------------------------------------------------

  @override
  Color get primary => accent;

  @override
  Color get onPrimary => bestOnColor(accent);

  @override
  Color get secondary => _desaturated(accent);

  @override
  Color get onSecondary => bestOnColor(_desaturated(accent));

  @override
  Color get accentA => accent;

  @override
  Color get accentB => _desaturated(accent, factor: 0.45);

  @override
  Color get glow => accent;

  @override
  Color get textOnPrimary => bestOnColor(accent);

  // Neutral backgrounds & surfaces — warm灰 that works with any accent.

  @override
  Color get background => isDark
      ? const Color(0xFF121218)
      : const Color(0xFFFAFAFA);

  @override
  Gradient get backgroundGradient => isDark
      ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF121218),
            HSLColor.fromColor(accent)
                .withLightness(0.12)
                .withSaturation(0.15)
                .toColor(),
            HSLColor.fromColor(accent)
                .withLightness(0.14)
                .withSaturation(0.10)
                .toColor(),
          ],
        )
      : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFFFAFAFA),
            HSLColor.fromColor(accent)
                .withLightness(0.97)
                .withSaturation(0.12)
                .toColor(),
            HSLColor.fromColor(accent)
                .withLightness(0.95)
                .withSaturation(0.08)
                .toColor(),
          ],
        );

  @override
  Color get surface => isDark
      ? const Color(0xFF1E1E26)
      : const Color(0xFFFFFFFF);

  @override
  Color get surfaceVariant => isDark
      ? const Color(0xFF282832)
      : const Color(0xFFF5F5F5);

  @override
  Color get textHigh =>
      isDark ? const Color(0xFFF0F0F5) : const Color(0xFF1A1A2E);

  @override
  Color get textLow =>
      isDark ? const Color(0xFF9E9EB0) : const Color(0xFF6E6E80);

  @override
  Color get border => isDark
      ? const Color(0xFF3A3A48)
      : const Color(0xFFE0E0E6);

  @override
  Color get divider => isDark
      ? const Color(0xFF2A2A34)
      : const Color(0xFFECECF0);

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
  double get glowBlur => 26;

  @override
  bool get useGlass => false;

  @override
  String get fontFamily => 'Chivo';
}
