import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/features/games/models/game_models.dart';
import 'package:sinclear_beyond/features/games/widgets/game_heroes_tab.dart';
import 'package:sinclear_beyond/features/games/widgets/game_matches_tab.dart';
import 'package:sinclear_beyond/features/games/widgets/game_overview_tab.dart';

Widget _wrap(Widget child) {
  return DesignScope(
    variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
    child: MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

DeadlockHeroStat _hero({
  required int id,
  required String name,
  int matches = 10,
  int wins = 6,
}) {
  return DeadlockHeroStat(
    heroId: id,
    heroName: name,
    heroIconUrl: null,
    matchesPlayed: matches,
    wins: wins,
    losses: matches - wins,
    winRate: matches == 0 ? 0 : wins / matches,
    timePlayedSeconds: matches * 2400,
    kills: matches * 5,
    deaths: matches * 3,
    assists: matches * 7,
    networthPerMin: 600,
    damagePerMin: 700,
    accuracy: 0.4,
  );
}

DeadlockMatch _match({int outcome = 1, int index = 0}) {
  return DeadlockMatch(
    matchId: 'm$index',
    heroId: 87,
    heroName: 'Nurse Harrow',
    heroLevel: 30,
    gameMode: 1,
    matchDurationSeconds: 2400,
    matchResult: outcome == 1 ? 0 : 1,
    playerTeam: 0,
    playerMatchOutcome: outcome,
    kills: 5,
    deaths: 3,
    assists: 7,
    netWorth: 24000,
  );
}

void main() {
  final stats = DeadlockStats(
    accountId: '179673173',
    rank: const DeadlockRank(tier: 5, subrank: 3, name: 'Mystic'),
    heroStats: <DeadlockHeroStat>[
      _hero(id: 2, name: 'Seven'),
      _hero(id: 7, name: 'Wraith', matches: 4, wins: 1),
    ],
    matchHistory: <DeadlockMatch>[
      _match(index: 0),
      _match(index: 1, outcome: 2),
      _match(index: 2),
    ],
  );

  testWidgets('Übersicht rendert Kennzahlen und Verlauf ohne Overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        GameOverviewTab(
          data: stats,
          summary: GameSummary.fromStats(stats),
          timezone: 'Europe/Berlin',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rang'), findsOneWidget);
    expect(find.text('Mystic III'), findsOneWidget);
    expect(find.text('Letzte Spiele'), findsOneWidget);
    expect(find.text('Top-Helden'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Helden-Tab sortiert und rendert Hero-Karten', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(GameHeroesTab(heroes: stats.heroStats, timezone: 'Europe/Berlin')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Seven'), findsOneWidget);
    expect(find.text('Wraith'), findsOneWidget);
    expect(find.text('Nach Winrate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Matches-Tab rendert Ergebnisse und Kennzahlen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        GameMatchesTab(matches: stats.matchHistory, timezone: 'Europe/Berlin'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Niederlage'), findsOneWidget);
    expect(find.text('Sieg'), findsNWidgets(2));
    expect(find.text('K / D / A'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
