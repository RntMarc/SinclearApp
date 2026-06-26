import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'dynamic_theme_service.dart';

class ThemeProvider extends InheritedWidget {
  const ThemeProvider({
    super.key,
    required this.palette,
    required this.service,
    required super.child,
  });

  final AppPalette palette;
  final DynamicThemeService service;

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  static AppPalette paletteOf(BuildContext context) {
    final provider = of(context);
    assert(provider != null, 'No ThemeProvider found in context');
    return provider!.palette;
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return palette != oldWidget.palette;
  }
}
