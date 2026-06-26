import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _primaryColor = Color(0xFF0064EA);
  static const _secondaryColor = Color(0xFFBC0091);
  static const _darkSurface = Color(0xFF011219);

  static CupertinoThemeData get cupertinoLight => const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    primaryContrastingColor: _secondaryColor,
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    barBackgroundColor: CupertinoColors.systemBackground,
    textTheme: CupertinoTextThemeData(
      primaryColor: _primaryColor,
    ),
  );

  static CupertinoThemeData get cupertinoDark => const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    primaryContrastingColor: _secondaryColor,
    scaffoldBackgroundColor: _darkSurface,
    barBackgroundColor: Color(0xE01C1C1E),
    textTheme: CupertinoTextThemeData(
      primaryColor: _primaryColor,
    ),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _secondaryColor,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _secondaryColor,
      brightness: Brightness.dark,
    ).copyWith(surface: _darkSurface),
  );
}
