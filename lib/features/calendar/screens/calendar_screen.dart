import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../travel/screens/event_detail_screen.dart';
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

  final Map<DateTime, List<CalendarEntry>> _entriesByDay = {};

  bool _hasLoaded = false;

  bool _loadingPast = true;
  bool _loadingFuture = true;
  String? _error;

  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 60));
  DateTime _rangeEnd = DateTime.now().add(const Duration(days: 90));

  bool _hasMorePast = true;
  bool _hasMoreFuture = true;

  final Map<DateTime, GlobalKey> _dayKeys = {};

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
      _entriesByDay.clear();
      _loadingPast = true;
      _loadingFuture = true;
      _error = null;
    });

    _rangeStart = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    _rangeEnd = DateTime(_focusedDay.year, _focusedDay.month + 2, 1);

    try {
      final results = await Future.wait([
        _service.all(start: _rangeStart, end: _focusedDay),
        _service.all(
          start: _focusedDay.add(const Duration(days: 1)),
          end: _rangeEnd,
        ),
      ]);

      _addEntries(results[0]);
      _addEntries(results[1]);

      _hasMorePast = results[0].truncated;
      _hasMoreFuture = results[1].truncated;
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToDay(DateTime.now());
      });
    }
  }

  Future<void> _refresh() async {
    _hasMorePast = true;
    _hasMoreFuture = true;
    await _loadInitial();
  }

  void _addEntries(CalendarAllResponse response) {
    for (final entry in response.data) {
      final start = entry.startTime;
      if (start == null) continue;
      final day = DateTime(start.year, start.month, start.day);
      final entries = _entriesByDay.putIfAbsent(day, () => []);
      if (!entries.any((e) => e.key == entry.key)) {
        entries.add(entry);
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
      final result = await _service.all(start: _rangeEnd, end: newEnd);
      _addEntries(result);
      _rangeEnd = newEnd;
      // ponytail: `truncated` gilt für die ganze Slice — bei >500 Einträgen
      // je Quelle im Slice würden Reste übersprungen (Verkleinerung statt
      // Erweiterung wäre der Ausweg). Für persönliche Feeds unrealistisch.
      _hasMoreFuture = result.truncated;
    } catch (e, st) {
      developer.log('Failed to load future events', error: e, stackTrace: st);
    }

    if (mounted) setState(() => _loadingFuture = false);
  }

  Future<void> _loadMorePast() async {
    setState(() => _loadingPast = true);

    final newStart = _rangeStart.subtract(const Duration(days: 60));

    try {
      final result = await _service.all(start: newStart, end: _rangeStart);
      _addEntries(result);
      _rangeStart = newStart;
      _hasMorePast = result.truncated;
    } catch (e, st) {
      developer.log('Failed to load past events', error: e, stackTrace: st);
    }

    if (mounted) setState(() => _loadingPast = false);
  }

  List<CalendarEntry> _getEntriesForDay(DateTime day) {
    return _entriesByDay[DateTime(day.year, day.month, day.day)] ?? [];
  }

  List<CalendarEntry> _getAllSortedEntries() {
    final all = <CalendarEntry>[];
    for (final entries in _entriesByDay.values) {
      all.addAll(entries);
    }
    all.sort((a, b) => a.startTime!.compareTo(b.startTime!));
    return all;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToDay(selectedDay));
  }

  void _scrollToDay(DateTime day) {
    final grouped = groupByDay(_getAllSortedEntries());
    if (grouped.isEmpty) return;
    final target = DateTime(day.year, day.month, day.day);
    final idx = grouped.indexWhere((e) => !e.key.isBefore(target));
    final d = idx >= 0 ? grouped[idx].key : grouped.last.key;
    final key = _dayKeys[d];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      alignment: 0.1,
      duration: const Duration(milliseconds: 250),
    );
  }

  Future<void> _createEvent({DateTime? initialDate}) async {
    final result = await showDesignSheet<Map<String, dynamic>>(
      context: context,
      child: const EventFormSheet(),
    );

    if (result == null || !mounted) return;

    try {
      final event = await _service.create(
        title: result['title'] as String,
        description: result['description'] as String?,
        startTime: result['startTime'] as DateTime,
        endTime: result['endTime'] as DateTime,
        visibility: result['visibility'] as int,
        participantIds: result['participantIds'] as List<String>?,
      );
      final entry = CalendarEntry.fromCalendarEvent(event);
      final day = DateTime(
        entry.startTime!.year,
        entry.startTime!.month,
        entry.startTime!.day,
      );
      setState(() {
        _entriesByDay.putIfAbsent(day, () => []).add(entry);
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

  /// Öffnet den zum Typ passenden Detail-Screen: nur echte Kalender-Events
  /// nutzen den Kalender-Detail-Screen, alle anderen Typen ihren eigenen.
  Future<void> _onEntryTap(CalendarEntry entry) async {
    switch (entry.type) {
      case CalendarEntryType.calendarEvent:
        await _openCalendarEvent(entry);
      case CalendarEntryType.travelEvent:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TravelEventDetailScreen(id: entry.id),
          ),
        );
      case CalendarEntryType.trip:
        context.push('/reisen/${entry.id}');
      case CalendarEntryType.ptJourney:
        context.push('/reisen/pt/${entry.id}');
      case CalendarEntryType.birthday:
        final userId = entry.targetId;
        if (userId == null) {
          developer.log('Geburtstags-Eintrag ohne Nutzer-ID', name: 'calendar');
          return;
        }
        context.push('/kontakte/$userId');
      default:
        developer.log(
          'Unbekannter Kalender-Eintragstyp: ${entry.type}',
          name: 'calendar',
        );
    }
  }

  Future<void> _openCalendarEvent(CalendarEntry entry) async {
    final result = await context.push('/kalender/${entry.id}');
    if (result == true && mounted) {
      setState(() {
        final day = DateTime(
          entry.startTime!.year,
          entry.startTime!.month,
          entry.startTime!.day,
        );
        _entriesByDay[day]?.removeWhere((e) => e.key == entry.key);
        if (_entriesByDay[day]?.isEmpty == true) {
          _entriesByDay.remove(day);
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
              entries: _getAllSortedEntries(),
              focusedDay: _focusedDay,
              selectedDay: _selectedDay,
              scrollController: _agendaScrollController,
              dayKeys: _dayKeys,
              onToday: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToDay(DateTime.now());
                });
              },
              onRefresh: _refresh,
              onDaySelected: _onDaySelected,
              eventLoader: _getEntriesForDay,
              onEntryTap: _onEntryTap,
              onCreateEvent: () => _createEvent(),
            )
          : _buildMobileLayout(tokens),
    );
  }

  Widget _buildMobileLayout(DesignTokens tokens) {
    final sorted = _getAllSortedEntries();
    final grouped = groupByDay(sorted);

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
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime.now();
                        _selectedDay = DateTime.now();
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToDay(DateTime.now());
                      });
                    },
                  ),
                  DesignIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  controller: _agendaScrollController,
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CalendarHeaderDelegate(
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        onDaySelected: _onDaySelected,
                        onPageChanged: (focused) {
                          setState(() => _focusedDay = focused);
                        },
                        eventLoader: _getEntriesForDay,
                      ),
                    ),
                    if (_error != null && sorted.isEmpty)
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
                        sorted.isEmpty)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 300,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: tokens.primary,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 100,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            for (final entry in grouped)
                              DaySection(
                                key: _dayKeys.putIfAbsent(
                                  entry.key,
                                  () => GlobalKey(),
                                ),
                                date: entry.key,
                                entries: entry.value,
                                onEntryTap: _onEntryTap,
                              ),
                          ]),
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

class _CalendarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CalendarHeaderDelegate({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.eventLoader,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onPageChanged;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final List<CalendarEntry> Function(DateTime day) eventLoader;

  static const double _minExtent = 48;
  static const double _rowHeight = 40;
  static const double _daysOfWeekHeight = 30;
  static const double _headerHeight = 56;
  static const double _extraPadding = 8;
  static const double _maxExtent =
      _headerHeight + _daysOfWeekHeight + _rowHeight * 6 + _extraPadding;

  @override
  double get minExtent => _minExtent;

  @override
  double get maxExtent => _maxExtent;

  @override
  bool shouldRebuild(covariant _CalendarHeaderDelegate oldDelegate) =>
      focusedDay != oldDelegate.focusedDay ||
      selectedDay != oldDelegate.selectedDay;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final tokens = DesignTheme.of(context);
    final collapsed = shrinkOffset > maxExtent - minExtent - 8;
    final monthLabel = DateFormat('MMMM yyyy', 'de').format(focusedDay);

    if (collapsed) {
      return Material(
        color: tokens.surface,
        child: InkWell(
          onTap: () {
            final scrollable = Scrollable.of(context);
            scrollable.position.animateTo(
              0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          },
          child: SizedBox(
            height: minExtent,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DesignText(
                    monthLabel,
                    style: DesignTextStyle.subtitle,
                    color: tokens.textHigh,
                  ),
                  SizedBox(width: tokens.spaceSm),
                  Icon(
                    Icons.expand_less_rounded,
                    size: 20,
                    color: tokens.textLow,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2035),
        focusedDay: focusedDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        rowHeight: _rowHeight,
        daysOfWeekHeight: _daysOfWeekHeight,
        sixWeekMonthsEnforced: true,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: (selected, focused) => onDaySelected(selected, focused),
        onPageChanged: onPageChanged,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: 'Monat'},
        locale: 'de',
        eventLoader: eventLoader,
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(4),
          defaultTextStyle: const TextStyle(fontSize: 14),
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
          markersMaxCount: 3,
          markerSize: 6,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          headerPadding: EdgeInsets.symmetric(vertical: 4),
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
