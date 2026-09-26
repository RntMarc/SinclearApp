import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_card.dart';

/// Ergebnisbalken einer Abstimmung oder Terminfindung.
///
/// Baut auf [DesignCard] + [DesignText] und den Design-Tokens auf; die
/// Füllbreite ergibt sich aus [percentage].
class DesignPollResultBar extends StatelessWidget {
  const DesignPollResultBar({
    required this.label,
    required this.votes,
    required this.percentage,
    this.selected = false,
    super.key,
  });

  final String label;
  final int votes;
  final double percentage;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final fraction = (percentage / 100).clamp(0.0, 1.0);
    final barColor = selected ? tokens.success : tokens.primary;

    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DesignText(
                  label,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              DesignText(
                '$votes · ${percentage.toStringAsFixed(0)}%',
                style: DesignTextStyle.label,
                color: tokens.textLow,
              ),
            ],
          ),
          SizedBox(height: tokens.spaceSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusPill),
            child: Stack(
              children: <Widget>[
                Container(height: 8, color: tokens.surfaceVariant),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(height: 8, color: barColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
