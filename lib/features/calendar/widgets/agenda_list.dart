import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/calendar_models.dart';

/// Icon je Eintragstyp des kombinierten Kalender-Feeds.
IconData calendarEntryIcon(String type) {
  return switch (type) {
    CalendarEntryType.calendarEvent => Icons.event_rounded,
    CalendarEntryType.travelEvent => Icons.local_activity_rounded,
    CalendarEntryType.trip => Icons.flight_rounded,
    CalendarEntryType.birthday => Icons.cake_rounded,
    CalendarEntryType.ptJourney => Icons.train_rounded,
    _ => Icons.event_rounded,
  };
}

/// Deutsches Label je Eintragstyp — macht die Arten im Kalender
/// unterscheidbar.
String calendarEntryLabel(String type) {
  return switch (type) {
    CalendarEntryType.calendarEvent => 'Termin',
    CalendarEntryType.travelEvent => 'Event',
    CalendarEntryType.trip => 'Reise',
    CalendarEntryType.birthday => 'Geburtstag',
    CalendarEntryType.ptJourney => 'ÖPNV-Fahrt',
    _ => 'Termin',
  };
}

Color _entryColor(String type, DesignTokens tokens) {
  return switch (type) {
    CalendarEntryType.calendarEvent => tokens.primary,
    CalendarEntryType.travelEvent => tokens.accentA,
    CalendarEntryType.trip => tokens.accentB,
    CalendarEntryType.birthday => tokens.success,
    CalendarEntryType.ptJourney => tokens.warning,
    _ => tokens.primary,
  };
}

/// Gruppiert Kalendereinträge nach Tag (aufsteigend sortiert).
List<MapEntry<DateTime, List<CalendarEntry>>> groupByDay(
  List<CalendarEntry> entries,
) {
  final sorted = entries.where((e) => e.startTime != null).toList()
    ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

  // ponytail: mehrtägige Einträge (Reisen) erscheinen nur an ihrem
  // Starttag — wie bisher bei mehreren Tagen übergreifenden Events.
  final map = <DateTime, List<CalendarEntry>>{};
  for (final entry in sorted) {
    final day = DateTime(
      entry.startTime!.year,
      entry.startTime!.month,
      entry.startTime!.day,
    );
    map.putIfAbsent(day, () => []).add(entry);
  }

  final grouped = map.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  return grouped;
}

class AgendaList extends StatelessWidget {
  final List<CalendarEntry> entries;
  final void Function(CalendarEntry entry)? onEntryTap;
  final ScrollController? scrollController;
  final double bottomPadding;
  final Map<DateTime, GlobalKey>? dayKeys;

  const AgendaList({
    super.key,
    required this.entries,
    this.onEntryTap,
    this.scrollController,
    this.bottomPadding = 0,
    this.dayKeys,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final grouped = groupByDay(entries);

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

    // ponytail: Eager Build für begrenzte Datenmenge (~3 Monate).
    // Ceiling: >500 Einträge → Upgrade-Pfad: scrollable_positioned_list.
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 8 + bottomPadding,
      ),
      children: [
        for (final entry in grouped)
          DaySection(
            key: dayKeys?[entry.key],
            date: entry.key,
            entries: entry.value,
            onEntryTap: onEntryTap,
          ),
      ],
    );
  }
}

class DaySection extends StatelessWidget {
  final DateTime date;
  final List<CalendarEntry> entries;
  final void Function(CalendarEntry entry)? onEntryTap;

  const DaySection({
    super.key,
    required this.date,
    required this.entries,
    this.onEntryTap,
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
        ...entries.map(
          (entry) => _EntryTile(
            entry: entry,
            onTap: onEntryTap != null ? () => onEntryTap!(entry) : null,
          ),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  final CalendarEntry entry;
  final VoidCallback? onTap;

  const _EntryTile({required this.entry, this.onTap});

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
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignText(
                    _timeLabel(),
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  DesignText(
                    _endLabel(),
                    style: DesignTextStyle.body,
                    color: tokens.textLow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Container(
              width: 2,
              height: 40,
              decoration: BoxDecoration(
                color: _entryColor(entry.type, tokens),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        calendarEntryIcon(entry.type),
                        size: 16,
                        color: tokens.textLow,
                      ),
                      SizedBox(width: tokens.spaceXs),
                      Expanded(
                        child: DesignText(
                          entry.title ?? calendarEntryLabel(entry.type),
                          style: DesignTextStyle.body,
                          color: tokens.textHigh,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  ?_subtitle(tokens),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: tokens.textLow),
          ],
        ),
      ),
    );
  }

  String _timeLabel() {
    if (entry.allDay) return 'Ganztägig';
    final start = entry.startTime;
    return start == null ? '–' : formatTime(start);
  }

  String _endLabel() {
    if (entry.allDay) return '';
    final end = entry.endTime;
    return end == null ? '' : formatTime(end);
  }

  /// Unterzeile: Typ-Label für alle Nicht-Kalender-Events; echte
  /// Kalender-Events zeigen Beschreibung und Teilnehmer aus `detail`.
  Widget? _subtitle(DesignTokens tokens) {
    if (entry.type != CalendarEntryType.calendarEvent) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: DesignText(
          calendarEntryLabel(entry.type),
          style: DesignTextStyle.label,
          color: tokens.textLow,
        ),
      );
    }

    final detail = entry.detail;
    final description = detail['description'] as String?;
    final participants = detail['participants'] as List?;

    if ((description == null || description.isEmpty) &&
        (participants == null || participants.isEmpty)) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (description != null && description.isNotEmpty)
            DesignText(
              description,
              style: DesignTextStyle.body,
              color: tokens.textLow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (participants != null && participants.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.people_rounded, size: 14, color: tokens.textLow),
                  SizedBox(width: tokens.spaceXs),
                  Expanded(
                    child: DesignText(
                      participants
                          .whereType<Map<String, dynamic>>()
                          .map((p) => p['displayName'] as String? ?? '')
                          .where((name) => name.isNotEmpty)
                          .join(', '),
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
