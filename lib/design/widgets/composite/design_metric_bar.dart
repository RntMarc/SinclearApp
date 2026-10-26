import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Waagerechter Fortschritts-/Anteilsbalken mit Label und Wert.
///
/// Modellfrei: [fraction] ist 0…1. Wird für Winrates, Helden-Anteile und
/// ähnliche Kennzahlen genutzt; die Farbe kommt standardmäßig aus
/// [DesignTokens.primary].
class DesignMetricBar extends StatelessWidget {
  const DesignMetricBar({
    required this.label,
    required this.fraction,
    this.valueText,
    this.color,
    this.leading,
    this.trailing,
    super.key,
  });

  final String label;
  final double fraction;
  final String? valueText;
  final Color? color;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final safeFraction = fraction.isFinite ? fraction.clamp(0.0, 1.0) : 0.0;
    final barColor = color ?? tokens.primary;
    return Semantics(
      label: valueText == null ? label : '$label: $valueText',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                leading!,
                SizedBox(width: tokens.spaceSm),
              ],
              Expanded(
                child: DesignText(
                  label,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (valueText != null) ...<Widget>[
                SizedBox(width: tokens.spaceSm),
                DesignText(
                  valueText!,
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                ),
              ],
              if (trailing != null) ...<Widget>[
                SizedBox(width: tokens.spaceSm),
                trailing!,
              ],
            ],
          ),
          SizedBox(height: tokens.spaceXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusPill),
            child: Stack(
              children: <Widget>[
                Container(height: 8, color: tokens.surfaceVariant),
                FractionallySizedBox(
                  widthFactor: safeFraction,
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
