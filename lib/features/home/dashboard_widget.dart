import 'package:flutter/material.dart';

/// Ein einzelner, serialisierbarer Anzeige-Datensatz eines Dashboard-Widgets.
abstract class DashboardRow {
  Map<String, dynamic> toJson();
}

/// Verhalten eines Widgets, wenn es keine Daten anzuzeigen hat.
enum WidgetEmptyState {
  /// Kompakte Leerkarte in voller Höhe – Layout springt nie.
  card,

  /// Nur im Bearbeitungsmodus sichtbar, im Normal-Modus ausgeblendet.
  hide,
}

/// Die im Dashboard verfügbaren Widget-Typen (Registry).
enum DashboardWidgetType {
  recipes(
    'Neue Rezepte',
    Icons.restaurant_rounded,
    'Die neuesten Rezepte der Community.',
    emptyText: 'Noch keine Rezepte.',
    countDefault: 3,
    countMin: 2,
    countMax: 5,
    emptyDefault: WidgetEmptyState.card,
  ),
  calendarAgenda(
    'Kommende Events',
    Icons.calendar_month_rounded,
    'Die nächsten Kalender-Events.',
    emptyText: 'Keine kommenden Events.',
    countDefault: 2,
    countMin: 1,
    countMax: 3,
    emptyDefault: WidgetEmptyState.card,
  ),
  nextTrip(
    'Nächster Ausflug',
    Icons.flight_rounded,
    'Deine nächste Reise oder dein nächstes Event.',
    emptyText: 'Keine anstehenden Ausflüge.',
    countFixed: 1,
    emptyDefault: WidgetEmptyState.hide,
  ),
  forumPosts(
    'Neue Beiträge',
    Icons.forum_rounded,
    'Die neuesten Beiträge aus deinen Foren.',
    emptyText: 'Noch keine Beiträge.',
    countDefault: 3,
    countMin: 2,
    countMax: 5,
    emptyDefault: WidgetEmptyState.hide,
  ),
  openPayments(
    'Offene Zahlungen',
    Icons.payments_rounded,
    'Abos, die noch nicht bezahlt wurden.',
    emptyText: 'Keine offenen Zahlungen.',
    countFixed: 3,
    emptyDefault: WidgetEmptyState.card,
  );

  const DashboardWidgetType(
    this.title,
    this.icon,
    this.description, {
    required this.emptyText,
    this.countDefault,
    this.countMin,
    this.countMax,
    this.countFixed,
    required this.emptyDefault,
  }) : assert(
         countFixed != null ||
             (countDefault != null && countMin != null && countMax != null),
         'Entweder countFixed oder countDefault/countMin/countMax setzen',
       );

  final String title;
  final IconData icon;
  final String description;
  final String emptyText;
  final WidgetEmptyState emptyDefault;

  /// Konfigurierbare Zeilenanzahl (nur gesetzt, wenn [countFixed] null ist).
  final int? countDefault;
  final int? countMin;
  final int? countMax;

  /// Feste Zeilenanzahl für Widgets ohne Nutzer-Konfiguration.
  final int? countFixed;

  bool get countConfigurable => countFixed == null;

  int initialCount() => countFixed ?? countDefault!;

  int clampCount(int value) => countFixed ?? value.clamp(countMin!, countMax!);
}

/// Konfiguration eines platzierten Widgets.
class DashboardWidgetConfig {
  final DashboardWidgetType type;
  final int count;
  final WidgetEmptyState emptyState;

  const DashboardWidgetConfig({
    required this.type,
    required this.count,
    required this.emptyState,
  });

  factory DashboardWidgetConfig.initial(DashboardWidgetType type) {
    return DashboardWidgetConfig(
      type: type,
      count: type.initialCount(),
      emptyState: type.emptyDefault,
    );
  }

  DashboardWidgetConfig copyWith({int? count, WidgetEmptyState? emptyState}) {
    return DashboardWidgetConfig(
      type: type,
      count: type.clampCount(count ?? this.count),
      emptyState: emptyState ?? this.emptyState,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'count': count,
    'emptyState': emptyState.name,
  };
}

/// Das komplette Dashboard-Layout: Reihenfolge der platzierten Widgets.
class DashboardLayout {
  final List<DashboardWidgetConfig> widgets;

  const DashboardLayout({required this.widgets});

  /// Standardlayout: alle Widgets, in fester Startreihenfolge.
  static DashboardLayout get defaults {
    return DashboardLayout(
      widgets: [
        for (final type in DashboardWidgetType.values)
          DashboardWidgetConfig.initial(type),
      ],
    );
  }

  factory DashboardLayout.fromJson(Map<String, dynamic> json) {
    final widgets = <DashboardWidgetConfig>[];
    for (final raw in (json['widgets'] as List? ?? const [])) {
      final map = raw as Map<String, dynamic>;
      final type = DashboardWidgetType.values.asNameMap()[map['type']];
      if (type == null) continue;
      if (widgets.any((config) => config.type == type)) continue;
      final count = (map['count'] as num?)?.toInt();
      final emptyState =
          WidgetEmptyState.values.asNameMap()[map['emptyState']] ??
          type.emptyDefault;
      widgets.add(
        DashboardWidgetConfig(
          type: type,
          count: type.clampCount(count ?? type.initialCount()),
          emptyState: emptyState,
        ),
      );
    }
    return DashboardLayout(widgets: widgets);
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'widgets': [for (final config in widgets) config.toJson()],
  };
}
