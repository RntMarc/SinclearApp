import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_card.dart';

/// Kompakte Kennzahl-Karte für Statistik-Übersichten.
///
/// Baut auf [DesignCard] + [DesignText] und den Design-Tokens auf; der
/// Aufrufer steuert das Raster (z. B. zwei Spalten auf Mobile).
class DesignStatTile extends StatelessWidget {
  const DesignStatTile({
    required this.label,
    required this.value,
    this.icon,
    this.emphasis = false,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;

  /// Hebt den Wert farblich hervor (z. B. Winrate oder Rang).
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: DesignCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.all(tokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 16, color: tokens.textLow),
                  SizedBox(width: tokens.spaceXs),
                ],
                Expanded(
                  child: DesignText(
                    label,
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceXs),
            DesignText(
              value,
              style: DesignTextStyle.subtitle,
              color: emphasis ? tokens.primary : tokens.textHigh,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
