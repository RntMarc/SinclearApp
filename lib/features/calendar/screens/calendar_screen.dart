import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../models/calendar_models.dart';
import '../services/calendar_service.dart';
import '../widgets/agenda_list.dart';
import '../widgets/calendar_widgets.dart';
import '../widgets/event_form_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarService get _service => AppScope.of(context).calendar;

  final ScrollController _agendaScrollController = ScrollController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<CalendarEvent>> _eventsByDay = {};

  bool _hasLoaded = false;

  bool _loadingPast = true;
  bool _loadingFuture = true;
  String? _error;

  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 60));
  DateTime _rangeEnd = DateTime.now().add(const Duration(days: 90));

  bool _hasMorePast = true;
  bool _hasMoreFuture = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _agendaScrollController.addListener(_onAgendaScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadInitial();
    }
  }

  @override
  void dispose() {
    _agendaScrollController.removeListener(_onAgendaScroll);
    _agendaScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _eventsByDay.clear();
      _loadingPast = true;
      _loadingFuture = true;
      _error = null;
    });

    _rangeStart = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    _rangeEnd = DateTime(_focusedDay.year, _focusedDay.month + 2, 1);

    try {
      final results = await Future.wait([
        _service.list(start: _rangeStart, end: _focusedDay, limit: 100),
        _service.list(
          start: _focusedDay.add(const Duration(days: 1)),
          end: _rangeEnd,
          limit: 100,
        ),
      ]);

      _addEvents(results[0]);
      _addEvents(results[1]);

      _hasMorePast = results[0].meta.hasMore;
      _hasMoreFuture = results[1].meta.hasMore;
    } catch (e, st) {
      developer.log('Failed to load calendar events', error: e, stackTrace: st);
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }

    if (mounted) {
      setState(() {
        _loadingPast = false;
        _loadingFuture = false;
      });
    }
  }

  Future<void> _refresh() async {
    _hasMorePast = true;
    _hasMoreFuture = true;
    await _loadInitial();
  }

  void _addEvents(CalendarEventListResponse response) {
    for (final event in response.data) {
      final day = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      final events = _eventsByDay.putIfAbsent(day, () => []);
      if (!events.any((e) => e.id == event.id)) {
        events.add(event);
      }
    }
  }

  void _onAgendaScroll() {
    final pos = _agendaScrollController.position;
    final maxScroll = pos.maxScrollExtent;
    final currentScroll = pos.pixels;

    if (currentScroll > maxScroll * 0.7 && _hasMoreFuture && !_loadingFuture) {
      _loadMoreFuture();
    }

    if (currentScroll < maxScroll * 0.2 && _hasMorePast && !_loadingPast) {
      _loadMorePast();
    }
  }

  Future<void> _loadMoreFuture() async {
    setState(() => _loadingFuture = true);

    final newEnd = _rangeEnd.add(const Duration(days: 60));

    try {
      final result = await _service.list(
        start: _rangeEnd,
        end: newEnd,
        page: 1,
        limit: 100,
      );
      _addEvents(result);
      _rangeEnd = newEnd;
      _hasMoreFuture = result.meta.hasMore;
    } catch (e, st) {
      developer.log('Failed to load future events', error: e, stackTrace: st);
    }

    if (mounted) setState(() => _loadingFuture = false);
  }

  Future<void> _loadMorePast() async {
    setState(() => _loadingPast = true);

    final newStart = _rangeStart.subtract(const Duration(days: 60));

    try {
      final result = await _service.list(
        start: newStart,
        end: _rangeStart,
        page: 1,
        limit: 100,
      );
      _addEvents(result);
      _rangeStart = newStart;
      _hasMorePast = result.meta.hasMore;
    } catch (e, st) {
      developer.log('Failed to load past events', error: e, stackTrace: st);
    }

    if (mounted) setState(() => _loadingPast = false);
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _eventsByDay[DateTime(day.year, day.month, day.day)] ?? [];
  }

  List<CalendarEvent> _getAllSortedEvents() {
    final all = <CalendarEvent>[];
    for (final events in _eventsByDay.values) {
      all.addAll(events);
    }
    all.sort((a, b) => a.startTime.compareTo(b.startTime));
    return all;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  Future<void> _createEvent({DateTime? initialDate}) async {
    final result = await showDesignSheet<Map<String, dynamic>>(
      context: context,
      child: EventFormSheet(),
    );

    if (result == null || !mounted) return;

    try {
      final event = await _service.create(
        title: result['title'] as String,
        description: result['description'] as String?,
        startTime: result['startTime'] as DateTime,
        endTime: result['endTime'] as DateTime,
        visibility: result['visibility'] as int,
      );
      final day = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      setState(() {
        _eventsByDay.putIfAbsent(day, () => []).add(event);
      });
    } catch (e, st) {
      developer.log('Failed to create event', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fehler beim Erstellen')));
      }
    }
  }

  void _onEventTap(CalendarEvent event) async {
    final result = await context.push('/kalender/${event.id}');
    if (result == true && mounted) {
      setState(() {
        final day = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );
        _eventsByDay[day]?.removeWhere((e) => e.id == event.id);
        if (_eventsByDay[day]?.isEmpty == true) {
          _eventsByDay.remove(day);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.shortestSide >= 600;

    return DesignSurface(
      child: isDesktop
          ? CalendarDesktopLayout(
              events: _getAllSortedEvents(),
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              scrollController: _agendaScrollController,
              onToday: () => setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              }),
              onRefresh: _refresh,
              onDaySelected: _onDaySelected,
              eventLoader: _getEventsForDay,
              onEventTap: _onEventTap,
              onCreateEvent: () => _createEvent(),
            )
          : _buildMobileLayout(tokens),
    );
  }

  Widget _buildMobileLayout(DesignTokens tokens) {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceLg,
                vertical: tokens.spaceXs,
              ),
              child: Row(
                children: [
                  const Spacer(),
                  DesignButton(
                    label: 'Heute',
                    variant: DesignButtonVariant.text,
                    icon: Icons.today_rounded,
                    onPressed: () => setState(() {
                      _focusedDay = DateTime.now();
                      _selectedDay = DateTime.now();
                    }),
                  ),
                  DesignIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            Expanded(
              child: CustomScrollView(
                controller: _agendaScrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Material(
                      type: MaterialType.transparency,
                      child: TableCalendar(
                        firstDay: DateTime(2020),
                        lastDay: DateTime(2035),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: _onDaySelected,
                        onPageChanged: (focused) {
                          setState(() => _focusedDay = focused);
                        },
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Monat',
                        },
                        locale: 'de',
                        eventLoader: _getEventsForDay,
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
                    ),
                  ),
                  if (_error != null && _getAllSortedEvents().isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: tokens.danger,
                              ),
                              SizedBox(height: tokens.spaceLg),
                              DesignText(
                                'Fehler beim Laden der Termine',
                                style: DesignTextStyle.subtitle,
                                color: tokens.textHigh,
                              ),
                              SizedBox(height: tokens.spaceSm),
                              DesignText(
                                _error!,
                                style: DesignTextStyle.body,
                                color: tokens.textLow,
                              ),
                              SizedBox(height: tokens.spaceLg),
                              DesignButton(
                                label: 'Erneut versuchen',
                                variant: DesignButtonVariant.filled,
                                icon: Icons.refresh_rounded,
                                onPressed: _refresh,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_loadingPast &&
                      _loadingFuture &&
                      _getAllSortedEvents().isEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(color: tokens.primary),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.zero,
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final events = _getAllSortedEvents();
                          return SizedBox(
                            height: 400,
                            child: AgendaList(
                              events: events,
                              onEventTap: _onEventTap,
                              scrollController: null,
                            ),
                          );
                        }, childCount: 1),
                      ),
                    ),
                  if (_loadingFuture || _loadingPast)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: tokens.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: tokens.spaceLg,
          bottom: tokens.spaceLg,
          child: DesignIconButton(
            icon: Icons.add_rounded,
            onPressed: () => _createEvent(initialDate: _selectedDay),
          ),
        ),
      ],
    );
  }

}


