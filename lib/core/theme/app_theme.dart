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
    fontSize: 22,
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      secondary: _secondaryColor,
      brightness: Brightness.light,
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
    ).copyWith(surface: _darkSurface),
    textTheme: TextTheme(
      titleLarge: _titleStyle,
      titleMedium: _subTitleStyle,
    ),
    appBarTheme: AppBarTheme(titleTextStyle: _titleStyle),
  );
}
