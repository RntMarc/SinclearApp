import 'dart:async' show unawaited;
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_variant.dart';

/// Persists the chosen design variant **locally on the device** (Android &
/// Web via `shared_preferences`). The selection is intentionally not stored in
/// the user profile or any API, and it survives logout/login and app restarts
/// until it is explicitly changed again.
class DesignPreferences {
  static const String _key = 'beyond.design_variant';

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
