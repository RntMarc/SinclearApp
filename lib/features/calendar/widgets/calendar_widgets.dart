import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/calendar_models.dart';
import 'agenda_list.dart';

class CalendarDesktopCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final List<CalendarEvent> Function(DateTime day) eventLoader;

  const CalendarDesktopCalendar({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    required this.onDaySelected,
    required this.eventLoader,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2035),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Monat'},
        locale: 'de',
        eventLoader: eventLoader,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: tokens.primary,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: tokens.primary,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }
}

class CalendarDesktopLayout extends StatelessWidget {
  final List<CalendarEvent> events;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final ScrollController scrollController;
  final VoidCallback onToday;
  final VoidCallback onRefresh;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final List<CalendarEvent> Function(DateTime day) eventLoader;
  final ValueChanged<CalendarEvent> onEventTap;
  final VoidCallback onCreateEvent;

  const CalendarDesktopLayout({
    super.key,
    required this.events,
    required this.focusedDay,
    this.selectedDay,
    required this.scrollController,
    required this.onToday,
    required this.onRefresh,
    required this.onDaySelected,
    required this.eventLoader,
    required this.onEventTap,
    required this.onCreateEvent,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceMd, tokens.spaceSm, tokens.spaceXs, 0,
                  ),
                  child: Row(
                    children: [
                      const Spacer(),
                      DesignButton(
                        label: 'Heute',
                        variant: DesignButtonVariant.text,
                        icon: Icons.today_rounded,
                        onPressed: onToday,
                      ),
                      DesignIconButton(
                        icon: Icons.refresh_rounded,
                        onPressed: onRefresh,
                      ),
                    ],
                  ),
                ),
                CalendarDesktopCalendar(
                  focusedDay: focusedDay,
                  selectedDay: selectedDay,
                  onDaySelected: onDaySelected,
                  eventLoader: eventLoader,
                ),
                SizedBox(height: tokens.spaceSm),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
                  child: SizedBox(
                    width: double.infinity,
                    child: DesignButton(
                      label: 'Neuer Termin',
                      variant: DesignButtonVariant.filled,
                      icon: Icons.add_rounded,
                      onPressed: onCreateEvent,
                    ),
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
              ],
            ),
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: tokens.border.withValues(alpha: 0.6),
        ),
        Expanded(
          child: AgendaList(
            events: events,
            onEventTap: onEventTap,
            scrollController: scrollController,
          ),
        ),
      ],
    );
  }
}
