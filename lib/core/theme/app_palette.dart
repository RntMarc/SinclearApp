import 'package:flutter/material.dart';

@immutable
class AppPalette {
  const AppPalette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.surface,
    required this.background,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.onBackground,
  });

  factory AppPalette.fromColors({
    required Color dominant,
    required Color vibrant,
    Color? muted,
  }) {
    final hsl = HSLColor.fromColor(dominant);
    final vibrantHsl = HSLColor.fromColor(vibrant);

    final secondary = muted ?? _generateSecondary(vibrantHsl);
    final tertiary = _generateTertiary(hsl);

    final isDark = hsl.lightness < 0.5;

    final surface = isDark
        ? _darken(dominant, 0.7)
        : _lighten(dominant, 0.85);

    final background = isDark
        ? _darken(dominant, 0.85)
        : _lighten(dominant, 0.95);

    return AppPalette(
      primary: _adjustSaturation(dominant, 0.7),
      secondary: _adjustSaturation(secondary, 0.6),
      tertiary: _adjustSaturation(tertiary, 0.5),
      surface: surface,
      background: background,
      onPrimary: _contrastColor(dominant),
      onSecondary: _contrastColor(secondary),
      onSurface: _contrastColor(surface),
      onBackground: _contrastColor(background),
    );
  }

  static AppPalette fallback() => const AppPalette(
        primary: Color(0xFF0064EA),
        secondary: Color(0xFFBC0091),
        tertiary: Color(0xFF00BCD4),
        surface: Color(0xFFF5F5F5),
        background: Color(0xFFFAFAFA),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF212121),
        onBackground: Color(0xFF212121),
      );

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color surface;
  final Color background;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color onBackground;

  Color get primaryContainer => _lighten(primary, 0.3);
  Color get secondaryContainer => _lighten(secondary, 0.3);
  Color get tertiaryContainer => _lighten(tertiary, 0.3);

  Color get primaryContainerDark => _darken(primary, 0.3);
  Color get secondaryContainerDark => _darken(secondary, 0.3);

  static Color _generateSecondary(HSLColor base) {
    final hue = (base.hue + 30.0) % 360.0;
    return HSLColor.fromAHSL(
      1.0,
      hue,
      (base.saturation * 0.8).clamp(0.0, 1.0),
      (base.lightness * 1.1).clamp(0.0, 1.0),
    ).toColor();
  }

  static Color _generateTertiary(HSLColor base) {
    final hue = (base.hue + 180.0) % 360.0;
    return HSLColor.fromAHSL(
      1.0,
      hue,
      (base.saturation * 0.5).clamp(0.0, 1.0),
      (base.lightness * 0.9).clamp(0.0, 1.0),
    ).toColor();
  }

  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _adjustSaturation(Color color, double targetSaturation) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withSaturation(targetSaturation).toColor();
  }

  static Color _contrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  AppPalette lerp(AppPalette other, double t) {
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPalette &&
          runtimeType == other.runtimeType &&
          primary == other.primary &&
          secondary == other.secondary &&
          tertiary == other.tertiary &&
          surface == other.surface &&
          background == other.background;

  @override
  int get hashCode => Object.hash(
        primary,
        secondary,
        tertiary,
        surface,
        background,
      );
}
