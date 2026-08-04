import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/widgets/primitives/design_card.dart';
import 'package:sinclear_beyond/features/home/dashboard_cache.dart';
import 'package:sinclear_beyond/features/home/dashboard_controller.dart';
import 'package:sinclear_beyond/features/home/dashboard_layout_store.dart';
import 'package:sinclear_beyond/features/home/dashboard_widget.dart';
import 'package:sinclear_beyond/features/home/dashboard_widget_spec.dart';
import 'package:sinclear_beyond/features/home/dashboard_widget_view.dart';
import 'package:sinclear_beyond/features/home/widgets/recipes_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DashboardLayout', () {
    test('Defaults: alle Widgets einmal, gültige Anzahlen', () {
      final layout = DashboardLayout.defaults;
      expect(layout.widgets.length, DashboardWidgetType.values.length);
      expect({
        for (final config in layout.widgets) config.type,
      }, DashboardWidgetType.values.toSet());
      for (final config in layout.widgets) {
        expect(config.count, inInclusiveRange(1, 5));
      }
    });

    test(
      'JSON: unbekannte und doppelte Typen übersprungen, count geklemmt',
      () {
        final layout = DashboardLayout.fromJson({
          'widgets': [
            {'type': 'recipes', 'count': 99, 'emptyState': 'hide'},
            {'type': 'recipes', 'count': 2},
            {'type': 'nonsense'},
            {'type': 'nextTrip', 'emptyState': 'weird'},
          ],
        });
        expect(layout.widgets.length, 2);
        expect(layout.widgets[0].count, 5);
        expect(layout.widgets[0].emptyState, WidgetEmptyState.hide);
        expect(layout.widgets[1].type, DashboardWidgetType.nextTrip);
        expect(layout.widgets[1].count, 1);
        expect(layout.widgets[1].emptyState, WidgetEmptyState.hide);
      },
    );

    test('Store: Roundtrip und korrupte Daten', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesDashboardLayoutStore();

      final layout = const DashboardLayout(
        widgets: [
          DashboardWidgetConfig(
            type: DashboardWidgetType.openPayments,
            count: 3,
            emptyState: WidgetEmptyState.hide,
          ),
          DashboardWidgetConfig(
            type: DashboardWidgetType.recipes,
            count: 2,
            emptyState: WidgetEmptyState.card,
          ),
        ],
      );
      await store.save(layout);

      final reloaded = await SharedPreferencesDashboardLayoutStore().load();
      expect(reloaded.widgets.length, 2);
      expect(reloaded.widgets[0].type, DashboardWidgetType.openPayments);
      expect(reloaded.widgets[0].emptyState, WidgetEmptyState.hide);
      expect(reloaded.widgets[1].count, 2);

      SharedPreferences.setMockInitialValues({
        'beyond.dashboard.layout': '{"kaputt":',
      });
      expect(
        (await SharedPreferencesDashboardLayoutStore().load()).widgets.length,
        DashboardWidgetType.values.length,
      );
    });
  });

  group('DashboardCache', () {
    test('schreibt und liest Zeilen pro Typ', () async {
      SharedPreferences.setMockInitialValues({});
      final cache = DashboardCache();
      final rows = [
        const RecipeRow(
          id: '1',
          title: 'T',
          category: 'C',
          createdAt: '2026-01-01',
        ),
      ];
      await cache.write(DashboardWidgetType.recipes, rows);

      final read = await cache.read(DashboardWidgetType.recipes);
      expect(read, isNotNull);
      expect(read!.length, 1);
      expect(read.first['title'], 'T');
      expect(await cache.read(DashboardWidgetType.forumPosts), isNull);
    });
  });

  group('DashboardController', () {
    DashboardController buildController() {
      SharedPreferences.setMockInitialValues({});
      return DashboardController(
        initialLayout: DashboardLayout.defaults,
        store: SharedPreferencesDashboardLayoutStore(),
        cache: DashboardCache(),
      );
    }

    test('Entfernen, Hinzufügen, Verschieben und Konfiguration', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      controller.removeWidget(0);
      expect(
        controller.layout.widgets.first.type,
        DashboardWidgetType.calendarAgenda,
      );

      controller.addWidget(DashboardWidgetType.recipes);
      expect(controller.layout.widgets.last.type, DashboardWidgetType.recipes);
      controller.addWidget(DashboardWidgetType.recipes);
      expect(
        controller.layout.widgets
            .where((c) => c.type == DashboardWidgetType.recipes)
            .length,
        1,
      );

      controller.moveWidget(controller.layout.widgets.length - 1, 0);
      expect(controller.layout.widgets.first.type, DashboardWidgetType.recipes);

      controller.updateConfig(DashboardWidgetType.openPayments, count: 9);
      expect(
        controller.configFor(DashboardWidgetType.openPayments).count,
        3, // countFixed klemmt auf 3
      );
      controller.updateConfig(DashboardWidgetType.recipes, count: 1);
      expect(controller.configFor(DashboardWidgetType.recipes).count, 2);

      final reloaded = await controller.store.load();
      expect(reloaded.widgets.length, DashboardWidgetType.values.length);
      expect(reloaded.widgets.first.type, DashboardWidgetType.recipes);
    });

    test('refreshAll lädt alle registrierten Refreshables', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      var calls = 0;
      final refreshable = _FakeRefreshable(() => calls++);
      controller.register(refreshable);
      await controller.refreshAll();
      expect(calls, 1);
      controller.unregister(refreshable);
      await controller.refreshAll();
      expect(calls, 1);
    });
  });

  group('DashboardWidgetView', () {
    testWidgets(
      'Höhe bleibt konstant: Skeleton == Daten == konfigurierte Anzahl',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final completer = Completer<List<DashboardRow>>();
        final controller = DashboardController(
          initialLayout: const DashboardLayout(
            widgets: [
              DashboardWidgetConfig(
                type: DashboardWidgetType.recipes,
                count: 3,
                emptyState: WidgetEmptyState.card,
              ),
            ],
          ),
          store: SharedPreferencesDashboardLayoutStore(),
          cache: DashboardCache(),
        );

        await tester.pumpWidget(
          _wrap(
            controller,
            _TestSpec(
              type: DashboardWidgetType.recipes,
              fetchFn: (count) => completer.future,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        final skeletonHeight = tester.getSize(find.byType(DesignCard)).height;
        // Header (52) + 3 Zeilen (3 × 60) + Card-Padding (2 × 16) + Margin
        // (2 × 4) + Border (2 × 1) – die feste Höhe des Widgets.
        expect(skeletonHeight, 274);

        completer.complete([_TestRow('Ein Rezept')]);
        await tester.pump();
        await tester.pump();

        expect(tester.getSize(find.byType(DesignCard)).height, skeletonHeight);
        expect(find.text('Ein Rezept'), findsOneWidget);

        controller.dispose();
      },
    );

    testWidgets(
      'Leer + hide: im Normal-Modus unsichtbar, im Edit-Modus sichtbar',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final controller = DashboardController(
          initialLayout: const DashboardLayout(
            widgets: [
              DashboardWidgetConfig(
                type: DashboardWidgetType.nextTrip,
                count: 1,
                emptyState: WidgetEmptyState.hide,
              ),
            ],
          ),
          store: SharedPreferencesDashboardLayoutStore(),
          cache: DashboardCache(),
        );

        await tester.pumpWidget(
          _wrap(
            controller,
            _TestSpec(
              type: DashboardWidgetType.nextTrip,
              fetchFn: (count) async => [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DesignCard), findsNothing);

        controller.toggleEditing();
        await tester.pump();
        expect(find.byType(DesignCard), findsOneWidget);
        expect(find.text('Keine anstehenden Ausflüge.'), findsOneWidget);

        controller.dispose();
      },
    );
  });
}

Widget _wrap(DashboardController controller, DashboardWidgetSpec spec) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: DesignScope(
          variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => DashboardWidgetView(
              controller: controller,
              spec: spec,
              index: 0,
              total: 1,
            ),
          ),
        ),
      ),
    ),
  );
}

class _FakeRefreshable implements DashboardRefreshable {
  _FakeRefreshable(this.onRefresh);

  final void Function() onRefresh;

  @override
  Future<void> refresh() async {
    onRefresh();
  }
}

class _TestRow implements DashboardRow {
  _TestRow(this.value);

  final String value;

  @override
  Map<String, dynamic> toJson() => {'value': value};
}

class _TestSpec extends DashboardWidgetSpec {
  _TestSpec({required this.type, required this.fetchFn});

  @override
  final DashboardWidgetType type;
  final Future<List<DashboardRow>> Function(int count) fetchFn;

  @override
  String get listRoute => '/rezepte';

  @override
  Future<List<DashboardRow>> fetch(int count) => fetchFn(count);

  @override
  DashboardRow rowFromJson(Map<String, dynamic> json) =>
      _TestRow(json['value'] as String);

  @override
  Widget rowBuilder(
    BuildContext context,
    DashboardRow row,
    VoidCallback? onTap,
  ) {
    return Text((row as _TestRow).value);
  }
}
