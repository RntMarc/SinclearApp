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
/// pausiert im Hintergrund und lädt beim Zurückkehren einmal nach, wenn der
/// letzte Refresh länger zurückliegt als das Intervall.
class DashboardController extends ChangeNotifier with WidgetsBindingObserver {
  DashboardController({
    required DashboardLayout initialLayout,
    required this.store,
    required this.cache,
    this.refreshInterval = const Duration(minutes: 5),
  }) : _layout = initialLayout {
    WidgetsBinding.instance.addObserver(this);
    _lastRefresh = DateTime.now();
    _timer = Timer.periodic(refreshInterval, (_) => refreshAll());
  }

  final DashboardLayoutStore store;
  final DashboardCache cache;
  final Duration refreshInterval;

  DashboardLayout _layout;
  DashboardLayout get layout => _layout;

  bool _editing = false;
  bool get editing => _editing;

  final List<DashboardRefreshable> _refreshables = [];
  Timer? _timer;
  DateTime? _lastRefresh;

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

  /// Lädt alle registrierten Widgets parallel neu (in-place, ohne Skeleton).
  Future<void> refreshAll() async {
    _lastRefresh = DateTime.now();
    await Future.wait([
      for (final refreshable in _refreshables) refreshable.refresh(),
    ]);
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
        final last = _lastRefresh;
        if (last == null ||
            DateTime.now().difference(last) >= refreshInterval) {
          refreshAll();
        }
        _timer ??= Timer.periodic(refreshInterval, (_) => refreshAll());
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}
