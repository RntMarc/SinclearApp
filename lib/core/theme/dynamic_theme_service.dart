import 'dart:math';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_palette.dart';

class DynamicThemeService extends ChangeNotifier {
  DynamicThemeService({SharedPreferences? prefs}) : _prefs = prefs;

  static const String _lastSelectionDateKey = 'dynamic_theme_last_date';
  static const String _selectedImageIndexKey = 'dynamic_theme_image_index';

  final SharedPreferences? _prefs;
  AppPalette _palette = AppPalette.fallback();
  int _selectedImageIndex = 0;
  bool _initialized = false;

  AppPalette get palette => _palette;
  bool get initialized => _initialized;

  List<String> _backgroundImages = [
    'assets/backgrounds/element-1163156101-1779383250309.jpg',
    'assets/backgrounds/element-1352233996-1779383150299.jpg',
    'assets/backgrounds/element-17630501-1779383164839.jpg',
    'assets/backgrounds/element-420173131-1779383181875.jpg',
    'assets/backgrounds/element-779341078-1779383014931.jpg',
  ];

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_lastSelectionDateKey);

    if (lastDate == today) {
      _selectedImageIndex = prefs.getInt(_selectedImageIndexKey) ?? 0;
    } else {
      final random = Random();
      _selectedImageIndex = random.nextInt(_backgroundImages.length);
      await prefs.setString(_lastSelectionDateKey, today);
      await prefs.setInt(_selectedImageIndexKey, _selectedImageIndex);
    }

    await _extractPaletteFromImage();
    _initialized = true;
    notifyListeners();
  }

  String get currentBackgroundImage =>
      _backgroundImages[_selectedImageIndex % _backgroundImages.length];

  List<String> get availableBackgroundImages => List.unmodifiable(_backgroundImages);

  void setBackgroundImages(List<String> images) {
    _backgroundImages = images;
    notifyListeners();
  }

  Future<void> forceRefresh() async {
    final random = Random();
    _selectedImageIndex = random.nextInt(_backgroundImages.length);

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_lastSelectionDateKey, today);
    await prefs.setInt(_selectedImageIndexKey, _selectedImageIndex);

    await _extractPaletteFromImage();
    notifyListeners();
  }

  Future<void> _extractPaletteFromImage() async {
    try {
      final imageProvider = AssetImage(currentBackgroundImage);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(200, 200),
        maximumColorCount: 16,
      );

      final dominant = paletteGenerator.dominantColor?.color;
      final vibrant = paletteGenerator.vibrantColor?.color;
      final muted = paletteGenerator.mutedColor?.color;

      if (dominant != null && vibrant != null) {
        _palette = AppPalette.fromColors(
          dominant: dominant,
          vibrant: vibrant,
          muted: muted,
        );
      } else {
        _palette = AppPalette.fallback();
      }
    } catch (e) {
      debugPrint('DynamicThemeService: Error extracting palette: $e');
      _palette = AppPalette.fallback();
    }
  }

  Future<Color?> extractDominantColor(String assetPath) async {
    try {
      final imageProvider = AssetImage(assetPath);
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(200, 200),
        maximumColorCount: 8,
      );
      return paletteGenerator.dominantColor?.color;
    } catch (e) {
      debugPrint('DynamicThemeService: Error extracting color from $assetPath: $e');
      return null;
    }
  }
}
