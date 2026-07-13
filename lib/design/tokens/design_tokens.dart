import 'package:flutter/material.dart';

/// Abstract design tokens for the custom (non-Material) design system.
///
/// Every visual decision in the widget catalog is driven by these values, so
/// nothing is hard-coded in widgets. Concrete variants ([MateriaPopTokens],
/// [AuroraGlassTokens], [LiquidPulseTokens]) supply light and dark instances.
///
/// The values are intentionally exposed as named getters (variables) so the
/// whole palette can be retuned from a single place.
abstract class DesignTokens {
  const DesignTokens(this.brightness);

  /// Whether these tokens describe the dark or light appearance.
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  // ---------------------------------------------------------------------------
  // Color primitives (all referenced by variable, never hard-coded elsewhere)
  // ---------------------------------------------------------------------------

  /// Page background base color (gradient is preferred, see [backgroundGradient]).
  Color get background;

  /// Multi-stop background gradient painted by [DesignSurface].
  Gradient get backgroundGradient;

  /// Raised surface color for cards and sheets.
  Color get surface;

  /// Secondary surface tint used for insets and chips.
  Color get surfaceVariant;

  /// Primary brand color (buttons, active states).
  Color get primary;

  /// Foreground color that sits on top of [primary].
  Color get onPrimary;

  /// Secondary brand color.
  Color get secondary;

  /// Foreground color that sits on top of [secondary].
  Color get onSecondary;

  /// First accent color (gradients, decorative patterns).
  Color get accentA;

  /// Second accent color.
  Color get accentB;

  /// High-emphasis text color.
  Color get textHigh;

  /// Low-emphasis / hint text color.
  Color get textLow;

  /// Text color used on filled primary buttons.
  Color get textOnPrimary;

  /// Hairline border color.
  Color get border;

  /// Subtle divider color.
  Color get divider;

  /// Glow color used for shadows on the accent elements.
  Color get glow;

  /// Positive semantic color.
  Color get success;

  /// Warning semantic color.
  Color get warning;

  /// Danger semantic color.
  Color get danger;

  // ---------------------------------------------------------------------------
  // Radii (corner rounding)
  // ---------------------------------------------------------------------------

  double get radiusSm;
  double get radiusMd;
  double get radiusLg;
  double get radiusXl;

  /// Fully rounded pill radius.
  double get radiusPill;

  // ---------------------------------------------------------------------------
  // Spacing scale (8pt-ish grid)
  // ---------------------------------------------------------------------------

  double get spaceXs; // 4
  double get spaceSm; // 8
  double get spaceMd; // 12
  double get spaceLg; // 16
  double get spaceXl; // 24
  double get spaceXxl; // 32

  // ---------------------------------------------------------------------------
  // Effects
  // ---------------------------------------------------------------------------

  /// Opacity of the film-grain overlay (0..1). Applied punctually, never full screen.
  double get grainOpacity;

  /// Blur sigma used by frosted-glass surfaces.
  double get glassBlur;

  /// Fill opacity of glass surfaces (0..1). Higher = less background bleed-through.
  double get glassOpacity => 0.65;

  /// Blur radius used by neon glow shadows.
  double get glowBlur;

  /// Whether cards/sheets should default to a glass surface.
  bool get useGlass;

  // ---------------------------------------------------------------------------
  // Typography
  // ---------------------------------------------------------------------------

  String get fontFamily;

  TextStyle displayStyle(Color color) => _style(color, 30, FontWeight.w900);
  TextStyle titleStyle(Color color) => _style(color, 22, FontWeight.w700);
  TextStyle subtitleStyle(Color color) => _style(color, 18, FontWeight.w700);
  TextStyle bodyStyle(Color color) => _style(color, 15, FontWeight.w400);
  TextStyle labelStyle(Color color) => _style(color, 13, FontWeight.w600);

  TextStyle _style(Color color, double size, FontWeight weight) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.35,
      decoration: TextDecoration.none,
    );
  }

  // ---------------------------------------------------------------------------
  // Elevation & shadows
  // ---------------------------------------------------------------------------

  /// Soft drop shadow for raised surfaces.
  List<BoxShadow> get surfaceShadow => <BoxShadow>[
        BoxShadow(
          color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.12),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  /// Colored glow shadow built around [glow].
  List<BoxShadow> get glowShadow => <BoxShadow>[
        BoxShadow(
          color: glow.withValues(alpha: 0.45),
          blurRadius: glowBlur,
          offset: const Offset(0, 6),
        ),
      ];
}
