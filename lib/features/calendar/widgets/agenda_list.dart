import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart';
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
    final grouped = _groupByDay(events);

    if (grouped.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_rounded,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Termine',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
    final theme = Theme.of(context);
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
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isToday
                    ? 'Heute'
                    : DateFormat('EEEE, d. MMMM yyyy', 'de').format(date),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                    Text(
                      formatTime(event.startTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      formatTime(event.endTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 2,
                height: 40,
                decoration: BoxDecoration(
                  color: _eventColor(event, theme),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (event.description != null &&
                        event.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          event.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.participants
                                  .map((p) => p.displayName)
                                  .join(', '),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
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
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _eventColor(CalendarEvent event, ThemeData theme) {
    switch (event.visibility) {
      case 0:
        return theme.colorScheme.primary;
      case 1:
        return theme.colorScheme.tertiary;
      case 2:
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.primary;
    }
  }
}
