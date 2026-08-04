import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_widget.dart';

/// Speichert das Dashboard-Layout (Reihenfolge, Konfiguration).
///
/// Gateway: heute lokal via [SharedPreferencesDashboardLayoutStore], später
/// über API-Endpunkte austauschbar – der Rest der App kennt die Quelle nicht.
abstract class DashboardLayoutStore {
  Future<DashboardLayout> load();
  Future<void> save(DashboardLayout layout);
}

class SharedPreferencesDashboardLayoutStore implements DashboardLayoutStore {
  static const _key = 'beyond.dashboard.layout';

  @override
  Future<DashboardLayout> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return DashboardLayout.defaults;
    try {
      return DashboardLayout.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return DashboardLayout.defaults;
    }
  }

  @override
  Future<void> save(DashboardLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(layout.toJson()));
  }
}
