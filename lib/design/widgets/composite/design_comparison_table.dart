import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_divider.dart';

/// Eine Zeile im [DesignComparisonTable].
///
/// [values] enthält je Spalte den bereits formatierten Anzeigewert.
/// [sortValues] ist optional und dient nur der Ermittlung des besseren Werts
/// (z. B. KDA als Zahl, Winrate als 0…1). [higherIsBetter] steuert, ob der
/// größte oder der kleinste Wert hervorgehoben wird.
class DesignComparisonRow {
  const DesignComparisonRow({
    required this.label,
    required this.values,
    this.sortValues,
    this.higherIsBetter = true,
  });

  final String label;
  final List<String> values;
  final List<double?>? sortValues;
  final bool higherIsBetter;
}

/// Modellfreier Vergleich zweier oder mehrerer Spalten.
///
/// Baut auf [DesignDivider] + [DesignText] und markiert den besseren Wert je
/// Zeile mit einem Pokal-Icon – zusätzlich zur (nicht alleinigen) Farbe.
class DesignComparisonTable extends StatelessWidget {
  const DesignComparisonTable({
    required this.columns,
    required this.rows,
    this.highlightLabel = 'Besser',
    super.key,
  });

  final List<String> columns;
  final List<DesignComparisonRow> rows;

  /// Semantik-/Tooltip-Beschreibung der Hervorhebung.
  final String highlightLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    if (columns.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Spacer(flex: 3),
            for (final column in columns)
              Expanded(
                flex: 2,
                child: DesignText(
                  column,
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        for (var index = 0; index < rows.length; index++) ...<Widget>[
          if (index > 0) const DesignDivider(),
          _row(context, tokens, rows[index]),
        ],
      ],
    );
  }

  Widget _row(
    BuildContext context,
    DesignTokens tokens,
    DesignComparisonRow row,
  ) {
    final bestIndex = _bestIndex(row);
    final semantics = <String>[
      for (var i = 0; i < columns.length && i < row.values.length; i++)
        '${columns[i]} ${row.values[i]}',
    ];

    return Semantics(
      label: '${row.label}: ${semantics.join(', ')}',
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: DesignText(
                row.label,
                style: DesignTextStyle.label,
                color: tokens.textLow,
                maxLines: 2,
              ),
            ),
            for (var i = 0; i < columns.length; i++)
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: DesignText(
                        i < row.values.length ? row.values[i] : '–',
                        style: DesignTextStyle.body,
                        color: i == bestIndex
                            ? tokens.primary
                            : tokens.textHigh,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        linkify: false,
                      ),
                    ),
                    if (i == bestIndex) ...<Widget>[
                      SizedBox(width: tokens.spaceXs),
                      Tooltip(
                        message: highlightLabel,
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: 14,
                          color: tokens.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _bestIndex(DesignComparisonRow row) {
    final values = row.sortValues;
    if (values == null || values.length < 2) return -1;
    double? best;
    var bestIndex = -1;
    var tie = false;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) continue;
      if (best == null) {
        best = value;
        bestIndex = i;
        continue;
      }
      final isBetter = row.higherIsBetter ? value > best : value < best;
      if (isBetter) {
        best = value;
        bestIndex = i;
        tie = false;
      } else if (value == best) {
        tie = true;
      }
    }
    if (tie || bestIndex < 0) return -1;
    return bestIndex;
  }
}
