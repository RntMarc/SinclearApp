import 'package:flutter/cupertino.dart';
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
              CupertinoIcons.calendar,
              size: 64,
              color: CupertinoColors.systemGrey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keine Termine',
              style: TextStyle(
                fontSize: 17,
                color: CupertinoColors.systemGrey,
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
    final theme = CupertinoTheme.of(context);
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
                      ? theme.primaryColor
                      : CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isToday
                    ? 'Heute'
                    : DateFormat('EEEE, d. MMMM yyyy', 'de').format(date),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isToday
                      ? theme.primaryColor
                      : theme.textTheme.textStyle.color,
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
    final theme = CupertinoTheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                  ),
                  Text(
                    formatTime(event.endTime),
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.textStyle.color,
                    ),
                  ),
                  if (event.description != null &&
                      event.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        event.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
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
                          const Icon(
                            CupertinoIcons.person_2,
                            size: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.participants
                                  .map((p) => p.displayName)
                                  .join(', '),
                              style: const TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.systemGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.systemGrey3,
            ),
          ],
        ),
      ),
    );
  }

  Color _eventColor(CalendarEvent event, CupertinoThemeData theme) {
    switch (event.visibility) {
      case 0:
        return theme.primaryColor;
      case 1:
        return CupertinoColors.systemGreen;
      case 2:
        return CupertinoColors.systemPurple;
      default:
        return theme.primaryColor;
    }
  }
}
