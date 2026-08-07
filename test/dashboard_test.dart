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
        // Header (44) + 3 Zeilen (3 × 60) + Card-Padding (2 × 12) + Margin
        // (2 × 4) + Border (2 × 1) – das Skeleton folgt der Konfiguration.
        expect(skeletonHeight, 258);

        completer.complete([_TestRow('Ein Rezept')]);
        await tester.pump();
        await tester.pump();

        // Mit Daten nur so hoch wie nötig: Header + 1 Zeile.
        expect(tester.getSize(find.byType(DesignCard)).height, 138);
        expect(find.text('Ein Rezept'), findsOneWidget);

        controller.dispose();
      },
    );

    testWidgets('Scrollen erzeugt keinen neuen Datenabruf (Keep-Alive)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      var fetchCalls = 0;
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

      // Leerer Cache (leere Antwort): ohne Keep-Alive würde jedes
      // Zurückscrollen einen neuen Abruf auslösen.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignScope(
              variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => ListView(
                  children: [
                    DashboardWidgetView(
                      controller: controller,
                      spec: _TestSpec(
                        type: DashboardWidgetType.recipes,
                        fetchFn: (count) async {
                          fetchCalls++;
                          return <DashboardRow>[];
                        },
                      ),
                      index: 0,
                      total: 1,
                    ),
                    const SizedBox(height: 1200),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(fetchCalls, 1);

      // Wegscrollen (Widget verlässt Viewport) und zurück.
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 900));
      await tester.pumpAndSettle();

      expect(fetchCalls, 1);

      controller.dispose();
    });

    testWidgets('Refresh-Durchlauf lädt alle Widgets, nicht nur das erste', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      var recipesCalls = 0;
      var agendaCalls = 0;
      var fakeNow = DateTime(2026, 1, 1, 12);
      final controller = DashboardController(
        initialLayout: const DashboardLayout(
          widgets: [
            DashboardWidgetConfig(
              type: DashboardWidgetType.recipes,
              count: 2,
              emptyState: WidgetEmptyState.card,
            ),
            DashboardWidgetConfig(
              type: DashboardWidgetType.calendarAgenda,
              count: 2,
              emptyState: WidgetEmptyState.card,
            ),
          ],
        ),
        store: SharedPreferencesDashboardLayoutStore(),
        cache: DashboardCache(),
        clock: () => fakeNow,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DesignScope(
              variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => ListView(
                  children: [
                    DashboardWidgetView(
                      controller: controller,
                      spec: _TestSpec(
                        type: DashboardWidgetType.recipes,
                        fetchFn: (count) async {
                          recipesCalls++;
                          return [_TestRow('R')];
                        },
                      ),
                      index: 0,
                      total: 2,
                    ),
                    DashboardWidgetView(
                      controller: controller,
                      spec: _TestSpec(
                        type: DashboardWidgetType.calendarAgenda,
                        fetchFn: (count) async {
                          agendaCalls++;
                          return [_TestRow('A')];
                        },
                      ),
                      index: 1,
                      total: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(recipesCalls, 1);
      expect(agendaCalls, 1);

      // Ein erlaubter Refresh-Durchlauf lädt beide Widgets nach, nicht nur
      // das zuerst registrierte.
      fakeNow = fakeNow.add(const Duration(seconds: 21));
      await controller.refreshAll();
      await tester.pumpAndSettle();
      expect(recipesCalls, 2);
      expect(agendaCalls, 2);

      controller.dispose();
    });

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

    testWidgets('Rate-Limit: max. 1 Datenabruf pro 20 s', (tester) async {
      SharedPreferences.setMockInitialValues({});
      var fetchCalls = 0;
      var fakeNow = DateTime(2026, 1, 1, 12);
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
        clock: () => fakeNow,
      );

      await tester.pumpWidget(
        _wrap(
          controller,
          _TestSpec(
            type: DashboardWidgetType.recipes,
            fetchFn: (count) async {
              fetchCalls++;
              return [_TestRow('Ein Rezept')];
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(fetchCalls, 1);

      // Zweiter Abruf innerhalb von 20 s wird nicht ausgeführt, aber als
      // aufgeschobener Sammel-Refresh vorgemerkt.
      await controller.refreshAll();
      await tester.pump();
      expect(fetchCalls, 1);

      // Nach Ablauf des Limits holt der aufgeschobene Refresh nach.
      fakeNow = fakeNow.add(const Duration(seconds: 21));
      await tester.pump(const Duration(seconds: 21));
      await tester.pump();
      expect(fetchCalls, 2);

      // Frisch abgerufen: ein weiterer Abruf innerhalb des Fensters bleibt
      // aus, ein aufgeschobener ist nur einmalig geplant.
      fakeNow = fakeNow.add(const Duration(seconds: 5));
      await controller.refreshAll();
      await tester.pump();
      expect(fetchCalls, 2);

      controller.dispose();
    });
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
