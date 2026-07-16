import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/calendar_models.dart';

class AgendaList extends StatelessWidget {
  final List<CalendarEvent> events;
  final void Function(CalendarEvent event)? onEventTap;
  final ScrollController? scrollController;

  const AgendaList({
    super.key,
    required this.events,
    this.onEventTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final grouped = _groupByDay(events);

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_rounded,
              size: 64,
              color: tokens.textLow.withValues(alpha: 0.4),
            ),
            SizedBox(height: tokens.spaceLg),
            DesignText(
              'Keine Termine',
              style: DesignTextStyle.subtitle,
              color: tokens.textLow,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped[index];
        return _DaySection(
          date: entry.key,
          events: entry.value,
          onEventTap: onEventTap,
        );
      },
    );
  }

  List<MapEntry<DateTime, List<CalendarEvent>>> _groupByDay(
    List<CalendarEvent> events,
  ) {
    final sorted = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final map = <DateTime, List<CalendarEvent>>{};
    for (final event in sorted) {
      final day = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      map.putIfAbsent(day, () => []).add(event);
    }

    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries;
  }
}

class _DaySection extends StatelessWidget {
  final DateTime date;
  final List<CalendarEvent> events;
  final void Function(CalendarEvent event)? onEventTap;

  const _DaySection({
    required this.date,
    required this.events,
    this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: isToday ? tokens.primary : tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              DesignText(
                isToday
                    ? 'Heute'
                    : DateFormat('EEEE, d. MMMM yyyy', 'de').format(date),
                style: DesignTextStyle.label,
                color: isToday ? tokens.primary : tokens.textHigh,
              ),
            ],
          ),
        ),
        ...events.map(
          (event) => _EventTile(
            event: event,
            onTap: onEventTap != null ? () => onEventTap!(event) : null,
          ),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;

  const _EventTile({required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignText(
                    formatTime(event.startTime),
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                  DesignText(
                    formatTime(event.endTime),
                    style: DesignTextStyle.body,
                    color: tokens.textLow,
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Container(
              width: 2,
              height: 40,
              decoration: BoxDecoration(
                color: _eventColor(event, tokens),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignText(
                    event.title,
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                  if (event.description != null &&
                      event.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: DesignText(
                        event.description!,
                        style: DesignTextStyle.body,
                        color: tokens.textLow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (event.participants.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 14,
                            color: tokens.textLow,
                          ),
                          SizedBox(width: tokens.spaceXs),
                          DesignText(
                            event.participants
                                .map((p) => p.displayName)
                                .join(', '),
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
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: tokens.textLow,
            ),
          ],
        ),
      ),
    );
  }

  Color _eventColor(CalendarEvent event, DesignTokens tokens) {
    switch (event.visibility) {
      case 0:
        return tokens.primary;
      case 1:
        return tokens.accentA;
      case 2:
        return tokens.secondary;
      default:
        return tokens.primary;
    }
  }
}
