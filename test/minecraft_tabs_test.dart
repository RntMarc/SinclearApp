import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/features/games/models/game_models.dart';
import 'package:sinclear_beyond/features/games/widgets/minecraft_overview_tab.dart';
import 'package:sinclear_beyond/features/games/widgets/minecraft_sources_tab.dart';

Widget _wrap(Widget child) {
  return DesignScope(
    variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

MinecraftStats _stats() {
  return const MinecraftStats(
    accountId: 'ca48cfb5-bfcb-4f25-bbbf-966cb5892c80',
    player: MinecraftPlayerInfo(
      uuid: 'ca48cfb5-bfcb-4f25-bbbf-966cb5892c80',
      name: 'Notch',
    ),
    sources: <MinecraftStatsSource>[
      MinecraftStatsSource(
        serverId: 'survival-1',
        world: 'world',
        collectedAt: '2026-11-27T21:00:00Z',
        stats: <String, Map<String, int>>{
          'minecraft:custom': <String, int>{
            'minecraft:play_time': 72000,
            'minecraft:deaths': 3,
            'minecraft:mob_kills': 14,
            'minecraft:jump': 5,
            'minecraft:walk_one_cm': 75000,
          },
          'minecraft:mined': <String, int>{'minecraft:stone': 100},
          'minecraft:killed': <String, int>{'minecraft:zombie': 10},
        },
      ),
    ],
    syncedAt: '2026-11-27T21:00:00Z',
  );
}

void main() {
  testWidgets('Minecraft-Übersicht rendert Kennzahlen und Top-Listen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(MinecraftOverviewTab(data: _stats(), timezone: 'Europe/Berlin')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spielzeit'), findsOneWidget);
    expect(find.text('Tode'), findsOneWidget);
    expect(find.text('Blöcke abgebaut'), findsOneWidget);
    expect(find.text('Top-Mobs'), findsOneWidget);
    expect(find.text('Top-Blöcke'), findsOneWidget);
    expect(find.text('1 Std. 0 Min.'), findsOneWidget);
  });

  testWidgets('Minecraft-Server-Tab rendert Quellen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(MinecraftSourcesTab(data: _stats(), timezone: 'Europe/Berlin')),
    );
    await tester.pumpAndSettle();

    expect(find.text('survival-1 · world'), findsOneWidget);
    expect(find.text('Spielzeit'), findsOneWidget);
    expect(find.text('Distanz'), findsOneWidget);
  });

  testWidgets('Server-Karte öffnet die Server-Statistik', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? opened;
    await tester.pumpWidget(
      _wrap(
        MinecraftSourcesTab(
          data: _stats(),
          timezone: 'Europe/Berlin',
          onOpenServer: (serverId) => opened = serverId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('survival-1 · world'));
    await tester.pumpAndSettle();

    expect(opened, 'survival-1');
  });
}
