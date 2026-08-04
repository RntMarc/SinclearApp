import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_widget.dart';

/// Persistenter Daten-Cache pro Widget-Typ.
///
/// Überlebt Sessions; Widgets rendern den Cache sofort und pflegen frische
/// Daten in-place ein (stale-while-revalidate). Web-kompatibel
/// (SharedPreferences statt Dateien).
class DashboardCache {
  static const _prefix = 'beyond.dashboard.cache';

  /// Liefert die gecachten Zeilen als JSON-Maps oder null, wenn keiner
  /// existiert (oder der Cache beschädigt ist).
  Future<List<Map<String, dynamic>>?> read(DashboardWidgetType type) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix.${type.name}');
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return (data['rows'] as List? ?? const []).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(DashboardWidgetType type, List<DashboardRow> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix.${type.name}',
      jsonEncode({
        'savedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
        'rows': [for (final row in rows) row.toJson()],
      }),
    );
  }
}
