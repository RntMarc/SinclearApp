import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../calendar/models/calendar_models.dart';
import '../../calendar/services/calendar_service.dart';
import '../dashboard_widget.dart';
import '../dashboard_widget_spec.dart';

/// Anzeige-Datensatz eines kommenden Kalender-Events.
class AgendaRow implements DashboardRow {
  final String id;
  final String title;
  final String? creator;
  final DateTime startTime;
  final DateTime endTime;

  const AgendaRow({
    required this.id,
    required this.title,
    this.creator,
    required this.startTime,
    required this.endTime,
  });

  factory AgendaRow.fromEvent(CalendarEvent event) {
    return AgendaRow(
      id: event.id,
      title: event.title,
      creator: event.creatorDisplayName,
      startTime: event.startTime,
      endTime: event.endTime,
    );
  }

  factory AgendaRow.fromJson(Map<String, dynamic> json) {
    return AgendaRow(
      id: json['id'] as String,
      title: json['title'] as String,
      creator: json['creator'] as String?,
      startTime: DateTime.fromMillisecondsSinceEpoch(json['start'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(json['end'] as int),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'creator': creator,
    'start': startTime.millisecondsSinceEpoch,
    'end': endTime.millisecondsSinceEpoch,
  };
}

/// Widget „Kommende Events“ – die nächsten Kalender-Events, laufende zuerst.
class AgendaWidgetSpec extends DashboardWidgetSpec {
  AgendaWidgetSpec(this._service);

  final CalendarService _service;

  @override
  DashboardWidgetType get type => DashboardWidgetType.calendarAgenda;

  @override
  String get listRoute => '/kalender';

  @override
  Future<List<DashboardRow>> fetch(int count) async {
    final now = DateTime.now();
    final response = await _service.list(
      page: 1,
      limit: 100,
      start: now,
      end: now.add(const Duration(days: 90)),
    );
    final events = response.data
        .where((event) => event.endTime.isAfter(now))
        .toList();
    events.sort((a, b) {
      final aOngoing = a.startTime.isBefore(now);
      final bOngoing = b.startTime.isBefore(now);
      if (aOngoing != bOngoing) return aOngoing ? -1 : 1;
      return a.startTime.compareTo(b.startTime);
    });
    return [for (final event in events.take(count)) AgendaRow.fromEvent(event)];
  }

  @override
  DashboardRow rowFromJson(Map<String, dynamic> json) =>
      AgendaRow.fromJson(json);

  @override
  Widget rowBuilder(
    BuildContext context,
    DashboardRow row,
    VoidCallback? onTap,
  ) {
    final event = row as AgendaRow;
    final tokens = DesignTheme.of(context);
    final day = DateFormat('d', 'de').format(event.startTime);
    final month = DateFormat('MMM', 'de').format(event.startTime);
    return PressScale(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tokens.surfaceVariant,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DesignText(
                  day,
                  style: DesignTextStyle.subtitle,
                  color: tokens.primary,
                ),
                DesignText(
                  month,
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  event.title,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: tokens.spaceXs),
                DesignText(
                  [
                    '${formatTime(event.startTime)} – ${formatTime(event.endTime)}',
                    if (event.creator != null) event.creator!,
                  ].join(' · '),
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
    context.go('/kalender/${(row as AgendaRow).id}');
  }
}
