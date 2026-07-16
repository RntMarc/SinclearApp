import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Renders the technical specs (radii, spacing, effects) of the active design
/// as a reference table. Used to document each design's measurements.
class DesignTokenSpec extends StatelessWidget {
  const DesignTokenSpec({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final rows = <(String, String)>[
      ('Radius SM', '${tokens.radiusSm.toStringAsFixed(0)} px'),
      ('Radius MD', '${tokens.radiusMd.toStringAsFixed(0)} px'),
      ('Radius LG', '${tokens.radiusLg.toStringAsFixed(0)} px'),
      ('Radius XL', '${tokens.radiusXl.toStringAsFixed(0)} px'),
      ('Pill', '${tokens.radiusPill.toStringAsFixed(0)} px'),
      ('Space XS', '${tokens.spaceXs.toStringAsFixed(0)} px'),
      ('Space LG', '${tokens.spaceLg.toStringAsFixed(0)} px'),
      ('Space XL', '${tokens.spaceXl.toStringAsFixed(0)} px'),
      ('Grain', '${(tokens.grainOpacity * 100).toStringAsFixed(0)} %'),
      ('Glass blur', '${tokens.glassBlur.toStringAsFixed(0)} px'),
      ('Glow blur', '${tokens.glowBlur.toStringAsFixed(0)} px'),
      ('Glass mode', tokens.useGlass ? 'an' : 'aus'),
    ];
    return Column(
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
          child: Row(
            children: <Widget>[
              Expanded(
                child: DesignText(
                  row.$1,
                  style: DesignTextStyle.body,
                  color: tokens.textLow,
                ),
              ),
              DesignText(
                row.$2,
                style: DesignTextStyle.label,
                color: tokens.textHigh,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
