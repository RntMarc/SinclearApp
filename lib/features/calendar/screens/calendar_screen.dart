import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/di/app_scope.dart';
import '../models/calendar_models.dart';
import '../services/calendar_service.dart';
import '../widgets/agenda_list.dart';
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
    final result = await showCupertinoModalPopup<Map<String, dynamic>>(
      context: context,
      builder: (_) => EventFormSheet(),
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
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            content: const Text('Fehler beim Erstellen'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
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
    final isDesktop = MediaQuery.of(context).size.shortestSide >= 600;

    if (isDesktop) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Kalender'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              onPressed: () => setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              }),
              padding: EdgeInsets.zero,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.today, size: 18),
                  Text('Heute'),
                ],
              ),
            ),
            CupertinoButton(
              onPressed: _refresh,
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.refresh),
            ),
            CupertinoButton(
              onPressed: () => _createEvent(initialDate: _selectedDay),
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add_circled),
            ),
          ],
        ),
      ),
      child: CustomScrollView(
        controller: _agendaScrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _CalendarHeaderDelegate(
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              eventsByDay: _eventsByDay,
              onDaySelected: _onDaySelected,
              onFormatChanged: (focused) {
                setState(() => _focusedDay = focused);
              },
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
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle,
                        size: 48,
                        color: CupertinoColors.destructiveRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fehler beim Laden der Termine',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .navTitleTextStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton.filled(
                        onPressed: _refresh,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.refresh, size: 18),
                            SizedBox(width: 8),
                            Text('Erneut versuchen'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_loadingPast &&
              _loadingFuture &&
              _getAllSortedEvents().isEmpty)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: Center(child: CupertinoActivityIndicator()),
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
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final events = _getAllSortedEvents();

    return CupertinoPageScaffold(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
                    child: Row(
                      children: [
                        Text(
                          'Kalender',
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .navLargeTitleTextStyle,
                        ),
                        const Spacer(),
                        CupertinoButton(
                          onPressed: () => setState(() {
                            _focusedDay = DateTime.now();
                            _selectedDay = DateTime.now();
                          }),
                          padding: EdgeInsets.zero,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.today, size: 18),
                              Text('Heute'),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          onPressed: _refresh,
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.refresh),
                        ),
                      ],
                    ),
                  ),
                  _buildDesktopCalendar(),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        onPressed: () => _createEvent(),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.plus, size: 18),
                            SizedBox(width: 8),
                            Text('Neuer Termin'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Container(
            width: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          Expanded(
            child: AgendaList(
              events: events,
              onEventTap: _onEventTap,
              scrollController: _agendaScrollController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCalendar() {
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return TableCalendar(
      firstDay: DateTime(2020),
      lastDay: DateTime(2035),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Monat'},
      locale: 'de',
      eventLoader: _getEventsForDay,
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }
}

class _CalendarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<CalendarEvent>> eventsByDay;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onFormatChanged;

  _CalendarHeaderDelegate({
    required this.focusedDay,
    required this.selectedDay,
    required this.eventsByDay,
    required this.onDaySelected,
    required this.onFormatChanged,
  });

  @override
  double get maxExtent {
    final weeks = _weeksInMonth(focusedDay);
    return 80 + (weeks * 52);
  }

  @override
  double get minExtent => 68;

  static int _weeksInMonth(DateTime date) {
    final first = DateTime(date.year, date.month, 1);
    final last = DateTime(date.year, date.month + 1, 0);
    return ((first.weekday - 1) + last.day + 6) ~/ 7;
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return eventsByDay[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final collapseRatio = (shrinkOffset / (maxExtent - minExtent)).clamp(
      0.0,
      1.0,
    );
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final bgColor = CupertinoColors.systemBackground.resolveFrom(context);

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          Opacity(
            opacity: 1.0 - collapseRatio,
            child: IgnorePointer(
              ignoring: collapseRatio > 0.5,
              child: SizedBox(
                height: maxExtent,
                child: TableCalendar(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2035),
                  focusedDay: focusedDay,
                  selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                  onDaySelected: onDaySelected,
                  onPageChanged: onFormatChanged,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Monat',
                  },
                  locale: 'de',
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: primaryColor,
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
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: collapseRatio,
              child: _WeekStrip(
                focusedDay: focusedDay,
                selectedDay: selectedDay,
                eventsByDay: eventsByDay,
                onDaySelected: (day) => onDaySelected(day, day),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_CalendarHeaderDelegate oldDelegate) {
    return focusedDay != oldDelegate.focusedDay ||
        selectedDay != oldDelegate.selectedDay ||
        eventsByDay != oldDelegate.eventsByDay;
  }
}

class _WeekStrip extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Map<DateTime, List<CalendarEvent>> eventsByDay;
  final ValueChanged<DateTime> onDaySelected;

  const _WeekStrip({
    required this.focusedDay,
    required this.selectedDay,
    required this.eventsByDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final primaryColor = theme.primaryColor;
    final bgColor = CupertinoColors.systemBackground.resolveFrom(context);
    final separatorColor = CupertinoColors.separator.resolveFrom(context);
    final secondaryLabelColor =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final weekStart = _weekStart(focusedDay);

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: separatorColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              DateFormat('MMMM yyyy', 'de').format(focusedDay),
              style: theme.textTheme.tabLabelTextStyle?.copyWith(
                fontWeight: FontWeight.w600,
                color: secondaryLabelColor,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: List.generate(7, (i) {
                final day = weekStart.add(Duration(days: i));
                final isSelected =
                    selectedDay != null && isSameDay(day, selectedDay!);
                final isToday = isSameDay(day, DateTime.now());
                final hasEvents = _getEventsForDay(day).isNotEmpty;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDaySelected(day),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E', 'de').format(day).substring(0, 2),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? CupertinoColors.white
                                  : secondaryLabelColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? CupertinoColors.white
                                  : isToday
                                      ? primaryColor
                                      : labelColor,
                            ),
                          ),
                          if (hasEvents)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? CupertinoColors.white
                                    : primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _weekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return eventsByDay[DateTime(day.year, day.month, day.day)] ?? [];
  }
}
