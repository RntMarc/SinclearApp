import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/design/design_variant.dart';
import 'package:sinclear_beyond/design/theme/design_theme.dart';
import 'package:sinclear_beyond/design/widgets/composite/design_bar_chart.dart';
import 'package:sinclear_beyond/design/widgets/composite/design_comparison_table.dart';
import 'package:sinclear_beyond/design/widgets/composite/design_metric_bar.dart';
import 'package:sinclear_beyond/design/widgets/composite/design_outcome_strip.dart';

Widget _wrap(Widget child) {
  return DesignScope(
    variant: ValueNotifier<DesignVariant>(DesignVariant.materiaPop),
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('DesignBarChart rendert Balken mit Semantik-Labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const DesignBarChart(
          bars: <DesignBar>[
            DesignBar(value: 10, semanticLabel: 'Match 1: 10'),
            DesignBar(value: 20, semanticLabel: 'Match 2: 20'),
            DesignBar(value: 0, semanticLabel: 'Match 3: 0'),
          ],
        ),
      ),
    );

    expect(find.bySemanticsLabel('Match 1: 10'), findsOneWidget);
    expect(find.bySemanticsLabel('Match 2: 20'), findsOneWidget);
    expect(find.bySemanticsLabel('Match 3: 0'), findsOneWidget);
  });

  testWidgets('DesignBarChart zeigt einen Leerzustand', (tester) async {
    await tester.pumpWidget(_wrap(const DesignBarChart(bars: <DesignBar>[])));
    expect(find.text('Keine Daten vorhanden.'), findsOneWidget);
  });

  testWidgets('DesignMetricBar zeigt Label und Prozentwert', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const DesignMetricBar(
          label: 'Winrate',
          fraction: 0.5,
          valueText: '50 %',
        ),
      ),
    );
    expect(find.text('Winrate'), findsOneWidget);
    expect(find.text('50 %'), findsOneWidget);
    expect(find.bySemanticsLabel('Winrate: 50 %'), findsOneWidget);
  });

  testWidgets(
    'DesignComparisonTable markiert nur den eindeutig besseren Wert',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DesignComparisonTable(
            columns: <String>['A', 'B'],
            rows: <DesignComparisonRow>[
              DesignComparisonRow(
                label: 'KDA',
                values: <String>['3,00', '4,00'],
                sortValues: <double?>[3, 4],
              ),
              DesignComparisonRow(
                label: 'Gleichstand',
                values: <String>['2,00', '2,00'],
                sortValues: <double?>[2, 2],
              ),
              DesignComparisonRow(
                label: 'Tode',
                values: <String>['2', '5'],
                sortValues: <double?>[2, 5],
                higherIsBetter: false,
              ),
            ],
          ),
        ),
      );

      expect(find.text('KDA'), findsOneWidget);
      expect(find.text('4,00'), findsOneWidget);
      // Nur KDA (B) und Tode (A) sind eindeutig besser.
      expect(find.byIcon(Icons.emoji_events_rounded), findsNWidgets(2));
    },
  );

  testWidgets('DesignOutcomeStrip zeigt Kurzform und vollständiges Label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const DesignOutcomeStrip(
          items: <DesignOutcomeItem>[
            DesignOutcomeItem(
              label: 'Sieg',
              shortLabel: 'S',
              tone: DesignOutcomeTone.positive,
            ),
            DesignOutcomeItem(
              label: 'Niederlage',
              shortLabel: 'N',
              tone: DesignOutcomeTone.negative,
            ),
          ],
        ),
      ),
    );

    expect(find.text('S'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.bySemanticsLabel('Sieg'), findsOneWidget);
    expect(find.bySemanticsLabel('Niederlage'), findsOneWidget);
  });
}
