import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const _primaryColor = Color(0xFF0064EA);
  static const _secondaryColor = Color(0xFFBC0091);
  static const _darkSurface = Color(0xFF011219);

  static TextStyle _titleStyle(Color color) => GoogleFonts.chivo(
    fontWeight: FontWeight.w900,
    fontStyle: FontStyle.italic,
    fontSize: 22,
    color: color,
  );

  static TextStyle _subTitleStyle(Color color) => GoogleFonts.chivo(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: color,
  );

  static ThemeData get light {
    final onSurface = const Color(0xFF1C1B1F);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        secondary: _secondaryColor,
        brightness: Brightness.light,
      ).copyWith(
        onSurface: onSurface,
      ),
      textTheme: TextTheme(
        titleLarge: _titleStyle(onSurface),
        titleMedium: _subTitleStyle(onSurface),
      ),
      appBarTheme: AppBarTheme(
        titleTextStyle: _titleStyle(onSurface),
        foregroundColor: onSurface,
      ),
    );
  }

  static ThemeData get dark {
    final onSurface = const Color(0xFFE6E1E5);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        secondary: _secondaryColor,
        brightness: Brightness.dark,
      ).copyWith(
        surface: _darkSurface,
        onSurface: onSurface,
      ),
      textTheme: TextTheme(
        titleLarge: _titleStyle(onSurface),
        titleMedium: _subTitleStyle(onSurface),
      ),
      appBarTheme: AppBarTheme(
        titleTextStyle: _titleStyle(onSurface),
        foregroundColor: onSurface,
      ),
    );
  }
}
