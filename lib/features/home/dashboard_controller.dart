import 'dart:async';

import 'package:flutter/widgets.dart';

import 'dashboard_cache.dart';
import 'dashboard_layout_store.dart';
import 'dashboard_widget.dart';

/// Widget, das bei [DashboardController.refreshAll] neu lädt.
abstract class DashboardRefreshable {
  Future<void> refresh();
}

/// Zentraler Zustand des Dashboards: Layout, Edit-Modus, Refresh-Takt.
///
/// Läuft im [AppScope] über die App-Lebensdauer. Der Auto-Refresh-Timer
/// pausiert im Hintergrund und lädt beim Zurückkehren einmal nach. Die
/// Datenabrufe unterliegen einem Rate-Limit von [minRefreshInterval]: Ein
/// Refresh-Durchlauf (= alle Widgets parallel) darf höchstens einmal im
/// Fenster starten, egal wie oft gewechselt oder gezogen wird.
class DashboardController extends ChangeNotifier with WidgetsBindingObserver {
  DashboardController({
    required DashboardLayout initialLayout,
    required this.store,
    required this.cache,
    this.refreshInterval = const Duration(minutes: 5),
    this.minRefreshInterval = const Duration(seconds: 20),
    DateTime Function() clock = DateTime.now,
  }) : // private Felder sind nicht als benannte Parameter erlaubt.
       // ignore: prefer_initializing_formals
       _clock = clock,
       _layout = initialLayout {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(refreshInterval, (_) => refreshAll());
  }

  final DashboardLayoutStore store;
  final DashboardCache cache;
  final Duration refreshInterval;

  /// Minimaler Abstand zwischen zwei Datenabrufen (Rate-Limit).
  final Duration minRefreshInterval;

  final DateTime Function() _clock;

  DashboardLayout _layout;
  DashboardLayout get layout => _layout;

  bool _editing = false;
  bool get editing => _editing;

  final List<DashboardRefreshable> _refreshables = [];
  Timer? _timer;

  /// Zeitpunkt des letzten Refresh-Durchlaufs.
  DateTime _lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  /// Einmaliger Sammel-Refresh, sobald das Rate-Limit es wieder erlaubt.
  Timer? _pendingRefresh;

  /// True, während [refreshAll] die registrierten Widgets abruft. Widgets
  /// belegen dann kein eigenes Slot, sondern nutzen den Durchlauf.
  bool _inRefreshPass = false;
  bool get inRefreshPass => _inRefreshPass;

  DashboardWidgetConfig configFor(DashboardWidgetType type) {
    for (final config in _layout.widgets) {
      if (config.type == type) return config;
    }
    return DashboardWidgetConfig.initial(type);
  }

  void toggleEditing() {
    _editing = !_editing;
    notifyListeners();
  }

  void addWidget(DashboardWidgetType type) {
    if (_layout.widgets.any((config) => config.type == type)) return;
    _layout = DashboardLayout(
      widgets: [..._layout.widgets, DashboardWidgetConfig.initial(type)],
    );
    _persist();
  }

  void removeWidget(int index) {
    if (index < 0 || index >= _layout.widgets.length) return;
    _layout = DashboardLayout(widgets: [..._layout.widgets]..removeAt(index));
    _persist();
  }

  void moveWidget(int from, int to) {
    final widgets = [..._layout.widgets];
    if (from < 0 || from >= widgets.length || to < 0 || to >= widgets.length) {
      return;
    }
    final moved = widgets.removeAt(from);
    widgets.insert(to, moved);
    _layout = DashboardLayout(widgets: widgets);
    _persist();
  }

  void updateConfig(
    DashboardWidgetType type, {
    int? count,
    WidgetEmptyState? emptyState,
  }) {
    _layout = DashboardLayout(
      widgets: [
        for (final config in _layout.widgets)
          config.type == type
              ? config.copyWith(count: count, emptyState: emptyState)
              : config,
      ],
    );
    _persist();
  }

  void register(DashboardRefreshable refreshable) {
    _refreshables.add(refreshable);
  }

  void unregister(DashboardRefreshable refreshable) {
    _refreshables.remove(refreshable);
  }

  /// Reserviert das Rate-Limit-Slot für einen Refresh-Durchlauf und liefert
  /// `true`, wenn jetzt geladen werden darf. Bei aktivem Limit wird ein
  /// einmaliger Sammel-Refresh auf den frühesten erlaubten Zeitpunkt
  /// aufgeschoben.
  bool claimRefreshPass() {
    final now = _clock();
    if (now.difference(_lastRefresh) >= minRefreshInterval) {
      _lastRefresh = now;
      _pendingRefresh?.cancel();
      _pendingRefresh = null;
      return true;
    }
    _pendingRefresh ??= Timer(
      minRefreshInterval - now.difference(_lastRefresh),
      refreshAll,
    );
    return false;
  }

  /// Lädt alle registrierten Widgets parallel nach und unterliegt dabei dem
  /// Rate-Limit: startet ein Durchlauf, laden ausnahmslos alle Widgets; ein
  /// Versuch innerhalb von [minRefreshInterval] wird aufgeschoben statt
  /// ausgeführt, bleibt aber als Sammel-Refresh bestehen.
  Future<void> refreshAll() async {
    _pendingRefresh?.cancel();
    _pendingRefresh = null;
    if (!claimRefreshPass()) return;
    _inRefreshPass = true;
    try {
      await Future.wait([
        for (final refreshable in _refreshables) refreshable.refresh(),
      ]);
    } finally {
      _inRefreshPass = false;
    }
  }

  void _persist() {
    notifyListeners();
    store.save(_layout);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        _timer?.cancel();
        _timer = null;
      case AppLifecycleState.resumed:
        // refreshAll unterliegt selbst dem Rate-Limit (max. 1 Durchlauf pro
        // minRefreshInterval), ein Stale-Check ist daher nicht nötig.
        refreshAll();
        _timer ??= Timer.periodic(refreshInterval, (_) => refreshAll());
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pendingRefresh?.cancel();
    super.dispose();
  }
}
