import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../travel/models/travel_models.dart';
import '../../travel/screens/event_detail_screen.dart';
import '../../travel/services/travel_service.dart';
import '../dashboard_widget.dart';
import '../dashboard_widget_spec.dart';

/// Anzeige-Datensatz des nächsten Ausflugs (Trip oder Standalone-Event).
class TripRow implements DashboardRow {
  final String id;
  final String name;
  final DateTime start;
  final DateTime end;
  final bool isTrip;
  final String? organizer;
  final String? address;

  const TripRow({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.isTrip,
    this.organizer,
    this.address,
  });

  factory TripRow.fromTrip(TravelTrip trip) {
    return TripRow(
      id: trip.id,
      name: trip.name,
      start: trip.start,
      end: trip.end,
      isTrip: true,
    );
  }

  factory TripRow.fromEvent(TravelEvent event) {
    return TripRow(
      id: event.id,
      name: event.name,
      start: event.start,
      end: event.end,
      isTrip: false,
      organizer: event.organizer,
      address: event.address,
    );
  }

  factory TripRow.fromJson(Map<String, dynamic> json) {
    return TripRow(
      id: json['id'] as String,
      name: json['name'] as String,
      start: DateTime.fromMillisecondsSinceEpoch(json['start'] as int),
      end: DateTime.fromMillisecondsSinceEpoch(json['end'] as int),
      isTrip: json['isTrip'] as bool,
      organizer: json['organizer'] as String?,
      address: json['address'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'isTrip': isTrip,
    'organizer': organizer,
    'address': address,
  };
}

/// Widget „Nächster Ausflug“ – das nächste anstehende Trip/Event.
///
/// Trips und Standalone-Events werden gemerged; ein gerade laufender Ausflug
/// schlägt das nächste zukünftige Event.
class TripWidgetSpec extends DashboardWidgetSpec {
  TripWidgetSpec(this._service);

  final TravelService _service;

  @override
  DashboardWidgetType get type => DashboardWidgetType.nextTrip;

  @override
  String get listRoute => '/reisen';

  @override
  Future<List<DashboardRow>> fetch(int count) async {
    final trips = (await _service.list(page: 1, limit: 100)).data;
    final events = (await _service.getStandaloneEvents(
      page: 1,
      limit: 100,
    )).data;
    final now = DateTime.now();

    final rows = <TripRow>[
      for (final trip in trips) TripRow.fromTrip(trip),
      for (final event in events) TripRow.fromEvent(event),
    ];
    rows.removeWhere((row) => row.end.isBefore(now));
    rows.sort((a, b) {
      final aOngoing = a.start.isBefore(now);
      final bOngoing = b.start.isBefore(now);
      if (aOngoing != bOngoing) return aOngoing ? -1 : 1;
      return a.start.compareTo(b.start);
    });
    return [for (final row in rows.take(count)) row];
  }

  @override
  DashboardRow rowFromJson(Map<String, dynamic> json) => TripRow.fromJson(json);

  @override
  Widget rowBuilder(
    BuildContext context,
    DashboardRow row,
    VoidCallback? onTap,
  ) {
    final trip = row as TripRow;
    final tokens = DesignTheme.of(context);
    final subtitle = [
      formatDateRange(trip.start, trip.end),
      if (!trip.isTrip && trip.organizer != null) trip.organizer!,
    ].join(' · ');
    return PressScale(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.surfaceVariant,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Icon(
              trip.isTrip ? Icons.flight_rounded : Icons.event_rounded,
              size: 18,
              color: tokens.primary,
            ),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  trip.name,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: tokens.spaceXs),
                DesignText(
                  subtitle,
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onRowTap(BuildContext context, DashboardRow row) {
    final trip = row as TripRow;
    if (trip.isTrip) {
      context.go('/reisen/${trip.id}');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TravelEventDetailScreen(id: trip.id),
        ),
      );
    }
  }
}
