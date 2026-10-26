import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_badge.dart';
import '../primitives/press_scale.dart';

/// Ein Eintrag der [DesignTabBar].
class DesignTabBarItem {
  const DesignTabBarItem({
    required this.icon,
    required this.label,
    this.badgeLabel,
  });

  final IconData icon;
  final String label;

  /// Optionaler Zähler rechts vom Label (z. B. ungelesene Chats).
  final String? badgeLabel;
}

/// Segmentierte Tab-Leiste im Pill-Stil (z. B. Dashboard | Chat).
///
/// Genau ein Eintrag ist aktiv und die Einträge teilen sich die volle Breite.
/// Für Mehrfach-Auswahl oder Sortier-Filter sind Chips die richtige Wahl.
class DesignTabBar extends StatelessWidget {
  const DesignTabBar({
    required this.items,
    required this.index,
    required this.onChanged,
    this.padding,
    super.key,
  });

  final List<DesignTabBarItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  /// Äußerer Abstand. Standard ist `spaceLg` horizontal und unten, `spaceMd`
  /// oben – passend zur Tab-Leiste des Home-Screens.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding:
          padding ??
          EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceMd,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: tokens.surfaceVariant.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(tokens.radiusPill),
          border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: <Widget>[
            for (var i = 0; i < items.length; i++)
              _segment(context, tokens, items[i], i),
          ],
        ),
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    DesignTokens tokens,
    DesignTabBarItem item,
    int segmentIndex,
  ) {
    final active = segmentIndex == index;
    final fg = active ? tokens.textOnPrimary : tokens.textHigh;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: PressScale(
          onTap: () => onChanged(segmentIndex),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
            decoration: BoxDecoration(
              color: active ? tokens.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(tokens.radiusPill),
              boxShadow: active ? tokens.glowShadow : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(item.icon, size: 18, color: fg),
                SizedBox(width: tokens.spaceSm),
                Flexible(
                  child: DesignText(
                    item.label,
                    style: DesignTextStyle.label,
                    color: fg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.badgeLabel != null) ...<Widget>[
                  SizedBox(width: tokens.spaceSm),
                  DesignBadge(label: item.badgeLabel!, color: tokens.accentA),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
