import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Semantische Einordnung eines Ergebnisses.
enum DesignOutcomeTone { positive, negative, neutral }

/// Ein Eintrag im [DesignOutcomeStrip].
class DesignOutcomeItem {
  const DesignOutcomeItem({
    required this.label,
    this.shortLabel,
    this.tone = DesignOutcomeTone.neutral,
  });

  /// Vollständige Beschreibung (Screenreader/Tooltip), z. B. „Sieg“.
  final String label;

  /// Kurzform im Chip, z. B. „S“.
  final String? shortLabel;

  final DesignOutcomeTone tone;
}

/// Kompakte Ergebnis-Reihe (z. B. die letzten 20 Spiele).
///
/// Die Information steht immer auch als Text im Chip und im Semantik-Label
/// bereit – Farbe ist nur eine zusätzliche Codierung.
class DesignOutcomeStrip extends StatelessWidget {
  const DesignOutcomeStrip({
    required this.items,
    this.emptyLabel = 'Noch keine Spiele.',
    super.key,
  });

  final List<DesignOutcomeItem> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    if (items.isEmpty) {
      return DesignText(
        emptyLabel,
        style: DesignTextStyle.label,
        color: tokens.textLow,
      );
    }

    return Wrap(
      spacing: tokens.spaceXs,
      runSpacing: tokens.spaceXs,
      children: <Widget>[
        for (final item in items)
          Semantics(
            label: item.label,
            excludeSemantics: true,
            child: Tooltip(
              message: item.label,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _background(tokens, item.tone),
                  borderRadius: BorderRadius.circular(tokens.radiusSm / 2),
                  border: Border.all(
                    color: tokens.border.withValues(alpha: 0.5),
                  ),
                ),
                child: DesignText(
                  item.shortLabel ?? item.label,
                  style: DesignTextStyle.label,
                  color: _foreground(tokens, item.tone),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _background(DesignTokens tokens, DesignOutcomeTone tone) {
    return switch (tone) {
      DesignOutcomeTone.positive => tokens.success.withValues(alpha: 0.18),
      DesignOutcomeTone.negative => tokens.danger.withValues(alpha: 0.18),
      DesignOutcomeTone.neutral => tokens.surfaceVariant,
    };
  }

  Color _foreground(DesignTokens tokens, DesignOutcomeTone tone) {
    return switch (tone) {
      DesignOutcomeTone.positive => tokens.success,
      DesignOutcomeTone.negative => tokens.danger,
      DesignOutcomeTone.neutral => tokens.textLow,
    };
  }
}
