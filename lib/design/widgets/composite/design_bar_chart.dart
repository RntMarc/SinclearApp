import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Ein Balken im [DesignBarChart].
class DesignBar {
  const DesignBar({
    required this.value,
    this.label = '',
    this.semanticLabel,
    this.color,
  });

  final double value;

  /// Optionale X-Beschriftung unter dem Balken.
  final String label;

  /// Vollständige Beschreibung für Screenreader.
  final String? semanticLabel;

  /// Überschreibt die Standardfarbe des Designs.
  final Color? color;
}

/// Vertikales Balkendiagramm ohne externe Chart-Dependency.
///
/// Modellfrei: Der Aufrufer liefert [DesignBar]s (Wert, optionales Label,
/// Farbe). Werte werden zusätzlich als Semantik-Label ausgegeben, damit die
/// Information nicht allein über die Balkenhöhe/Farbe transportiert wird.
class DesignBarChart extends StatelessWidget {
  const DesignBarChart({
    required this.bars,
    this.height = 140,
    this.emptyLabel = 'Keine Daten vorhanden.',
    super.key,
  });

  final List<DesignBar> bars;
  final double height;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    if (bars.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceLg),
        child: DesignText(
          emptyLabel,
          style: DesignTextStyle.label,
          color: tokens.textLow,
        ),
      );
    }

    var maxValue = 0.0;
    for (final bar in bars) {
      if (bar.value > maxValue) maxValue = bar.value;
    }
    if (maxValue <= 0) maxValue = 1;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: bars.map((bar) {
          final fraction = math.max(0.0, bar.value / maxValue).clamp(0.0, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Semantics(
                label:
                    bar.semanticLabel ??
                    (bar.label.isEmpty
                        ? bar.value.toStringAsFixed(0)
                        : '${bar.label}: ${bar.value.toStringAsFixed(0)}'),
                excludeSemantics: true,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: fraction,
                          widthFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: bar.color ?? tokens.primary,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(tokens.radiusSm / 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (bar.label.isNotEmpty) ...<Widget>[
                      SizedBox(height: tokens.spaceXs),
                      DesignText(
                        bar.label,
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
