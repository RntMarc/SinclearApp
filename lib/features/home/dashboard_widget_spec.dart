import 'package:flutter/material.dart';

import 'dashboard_widget.dart';

/// Beschreibt, wie ein Dashboard-Widget Daten lädt, cachet und rendert.
///
/// Ein Widget besteht aus einer [fetch]-Funktion (unabhängiger Datenabruf),
/// der Cache-Serialisierung ([rowFromJson]) und dem kompakten Zeilen-Rendering
/// ([rowBuilder]). [listRoute] ist das Ziel des Header-Taps, [onRowTap] das
/// Detail-Ziel eines Eintrags (null = nicht navigierbar).
abstract class DashboardWidgetSpec {
  DashboardWidgetType get type;
  String get listRoute;
  Future<List<DashboardRow>> fetch(int count);
  DashboardRow rowFromJson(Map<String, dynamic> json);
  Widget rowBuilder(
    BuildContext context,
    DashboardRow row,
    VoidCallback? onTap,
  );

  /// Ob Zeilen antippbar sind (Detail-Navigation); false für Widgets, deren
  /// Zeilen kein Detail-Ziel haben (z.B. offene Zahlungen).
  bool get rowsTappable => true;

  void onRowTap(BuildContext context, DashboardRow row) {}
}
