import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Renders the active design's color palette as named swatches.
class DesignColorSwatch extends StatelessWidget {
  const DesignColorSwatch({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final entries = <(String, Color)>[
      ('background', tokens.background),
      ('surface', tokens.surface),
      ('primary', tokens.primary),
      ('secondary', tokens.secondary),
      ('accentA', tokens.accentA),
      ('accentB', tokens.accentB),
      ('textHigh', tokens.textHigh),
      ('textLow', tokens.textLow),
      ('glow', tokens.glow),
      ('success', tokens.success),
      ('warning', tokens.warning),
      ('danger', tokens.danger),
    ];
    return Wrap(
      spacing: tokens.spaceMd,
      runSpacing: tokens.spaceMd,
      children: entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 84,
              height: 56,
              decoration: BoxDecoration(
                color: entry.$2,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: Border.all(color: tokens.border.withValues(alpha: 0.6)),
                boxShadow: tokens.surfaceShadow,
              ),
            ),
            SizedBox(height: tokens.spaceXs),
            DesignText(entry.$1, style: DesignTextStyle.label, color: tokens.textLow),
            DesignText(
              '#${entry.$2.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
        );
      }).toList(),
    );
  }
}
