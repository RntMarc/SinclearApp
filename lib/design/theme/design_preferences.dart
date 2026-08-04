import 'dart:async' show unawaited;
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_variant.dart';

/// Persists local device preferences (Android & Web via
/// `shared_preferences`). These are intentionally not stored in the user
/// profile or any API, and they survive logout/login and app restarts until
/// they are explicitly changed again.
class DesignPreferences {
  static const String _key = 'beyond.design_variant';
  static const String _grainKey = 'beyond.grain_opacity';
  static const String _themeModeKey = 'beyond.theme_mode';

  /// Loads the persisted variant, falling back to [DesignVariant.materiaPop].
  static Future<DesignVariant> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null) return DesignVariant.materiaPop;
    return DesignVariant.values.firstWhere(
      (v) => v.name == value,
      orElse: () => DesignVariant.materiaPop,
    );
  }

  /// Persists the chosen variant. Errors are swallowed so a failing store
  /// (e.g. in tests) never breaks the UI.
  static Future<void> save(DesignVariant variant) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, variant.name);
    } catch (e, st) {
      developer.log('DesignPreferences.save failed', error: e, stackTrace: st);
    }
  }

  /// Loads the persisted grain opacity fraction (0..1), falling back to `0`
  /// (off). The actual overlay opacity is `fraction * tokens.grainOpacity`.
  static Future<double> loadGrainOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_grainKey) ?? 0.0;
  }

  /// Persists the grain opacity fraction (0..1). Errors are swallowed so a
  /// failing store (e.g. in tests) never breaks the UI.
  static Future<void> saveGrainOpacity(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_grainKey, value);
    } catch (e, st) {
      developer.log('DesignPreferences.saveGrainOpacity failed',
          error: e, stackTrace: st);
    }
  }

  /// Loads the persisted theme mode, falling back to [ThemeMode.system].
  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    if (value == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  /// Persists the chosen theme mode. Errors are swallowed so a failing store
  /// (e.g. in tests) never breaks the UI.
  static Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, mode.name);
    } catch (e, st) {
      developer.log('DesignPreferences.saveThemeMode failed',
          error: e, stackTrace: st);
    }
  }
}

/// A [ValueNotifier] that automatically persists every change via
/// [DesignPreferences]. Used as the single source of truth for the active
/// design throughout the app (see [DesignScope]).
class DesignController extends ValueNotifier<DesignVariant> {
  DesignController(super.value);

  @override
  set value(DesignVariant newValue) {
    if (newValue == value) return;
    super.value = newValue;
    unawaited(DesignPreferences.save(newValue));
  }
}

/// A [ValueNotifier] that automatically persists every change via
/// [DesignPreferences]. The value is a fraction (0..1) representing the
/// grain intensity relative to the current design variant's max opacity.
class GrainController extends ValueNotifier<double> {
  GrainController(super.value);

  @override
  set value(double newValue) {
    final clamped = newValue.clamp(0.0, 1.0);
    if (clamped == value) return;
    super.value = clamped;
    unawaited(DesignPreferences.saveGrainOpacity(clamped));
  }
}

/// A [ValueNotifier] that automatically persists every change via
/// [DesignPreferences]. Controls whether the app follows the system theme,
/// or forces light / dark mode.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController(super.value);

  @override
  set value(ThemeMode newValue) {
    if (newValue == value) return;
    super.value = newValue;
    unawaited(DesignPreferences.saveThemeMode(newValue));
  }
}
