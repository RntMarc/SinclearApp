import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_badge.dart';
import '../primitives/design_card.dart';

/// Modell-freier Listeneintrag für eine Umfrage.
///
/// Baut ausschließlich auf Katalog-Widgets auf ([DesignCard], [DesignText],
/// [DesignBadge]) und kennt kein Feature-Modell. Feature-Screens mappen ihre
/// `Poll`-Objekte auf diese Parameter (Adapter `PollCard`).
class DesignPollCard extends StatelessWidget {
  const DesignPollCard({
    required this.title,
    required this.typeLabel,
    required this.typeIcon,
    required this.statusLabel,
    this.creatorLabel,
    this.deadlineLabel,
    this.closed = false,
    this.pulseColor,
    this.onTap,
    super.key,
  });

  final String title;
  final String typeLabel;
  final IconData typeIcon;
  final String statusLabel;
  final String? creatorLabel;
  final String? deadlineLabel;
  final bool closed;
  final Color? pulseColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final statusColor = closed ? tokens.textLow : tokens.success;
    final subtitle = <String>[
      if (creatorLabel != null && creatorLabel!.isNotEmpty) creatorLabel!,
      if (deadlineLabel != null && deadlineLabel!.isNotEmpty) deadlineLabel!,
    ].join(' · ');

    return DesignCard(
      pulseColor: pulseColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(typeIcon, size: 18, color: tokens.primary),
              SizedBox(width: tokens.spaceSm),
              DesignText(
                typeLabel,
                style: DesignTextStyle.label,
                color: tokens.primary,
              ),
              const Spacer(),
              DesignBadge(label: statusLabel, color: statusColor),
            ],
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            title,
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty) ...<Widget>[
            SizedBox(height: tokens.spaceXs),
            DesignText(
              subtitle,
              style: DesignTextStyle.label,
              color: tokens.textLow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
