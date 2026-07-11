import 'package:flutter/material.dart';

import '../tokens/beyond_tokens.dart';
import '../tokens/beyond_typography.dart';

/// Builds a full [ThemeData] for a brightness, tuned to the Aurora Glass look.
/// The catalog widgets read their values from [BeyondTokens] via the
/// [BuildContext.beyond] extension; this [ThemeData] mainly keeps default
/// Material widgets (and any not-yet-migrated screen) visually aligned.
class BeyondTheme {
  static ThemeData light() => _build(BeyondTokens.light());
  static ThemeData dark() => _build(BeyondTokens.dark());

  static ThemeData _build(BeyondTokens tokens) {
    final colors = tokens.color;
    final text = BeyondTypography.forColors(colors);

    return ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      scaffoldBackgroundColor: colors.surfaceBase,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.brandBlue,
        secondary: colors.brandMagenta,
        brightness: tokens.brightness,
      ).copyWith(
        surface: colors.surfaceBase,
        onSurface: colors.onSurface,
        primary: colors.brandBlue,
        secondary: colors.brandMagenta,
      ),
      textTheme: text.toMaterialTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: colors.brandBlue,
        unselectedItemColor: colors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.lg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceRaised,
        side: BorderSide.none,
        labelStyle: text.labelSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.pill),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceVariant,
        textColor: colors.onSurface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.md),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        labelStyle: text.label,
      ),
    );
  }
}

/// Access the resolved [BeyondTokens] for the current theme brightness.
extension BuildContextBeyond on BuildContext {
  BeyondTokens get beyond => BeyondTokens.forBrightness(
        Theme.of(this).brightness,
      );

  BeyondColors get beyondColor => beyond.color;
  BeyondTypography get beyondText => BeyondTypography.forColors(beyond.color);
}
