import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const _primaryColor = Color(0xFF0064EA);
  static const _secondaryColor = Color(0xFFBC0091);
  static const _darkSurface = Color(0xFF011219);

  static TextStyle get _titleStyle => GoogleFonts.chivo(
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    fontSize: 22,
  );

  static TextStyle get _subTitleStyle => GoogleFonts.chivo(
    fontWeight: FontWeight.w700,
    fontSize: 18,
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _secondaryColor,
      brightness: Brightness.light,
    ).copyWith(
      onSurface: const Color(0xFF1C1B1F),
    ),
    textTheme: TextTheme(
      titleLarge: _titleStyle,
      titleMedium: _subTitleStyle,
    ),
    appBarTheme: AppBarTheme(titleTextStyle: _titleStyle),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _secondaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      surface: _darkSurface,
      onSurface: const Color(0xFFE6E1E5),
    ),
    textTheme: TextTheme(
      titleLarge: _titleStyle,
      titleMedium: _subTitleStyle,
    ),
    appBarTheme: AppBarTheme(titleTextStyle: _titleStyle),
  );
}
