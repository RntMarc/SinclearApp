import 'package:material_ui/material_ui.dart';

import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/game_models.dart';
import '../utils/game_format.dart';

/// Statistikstand je Minecraft-Server und Welt.
class MinecraftSourcesTab extends StatelessWidget {
  const MinecraftSourcesTab({
    required this.data,
    required this.timezone,
    this.onOpenServer,
    super.key,
  });

  final MinecraftStats data;
  final String timezone;

  /// Öffnet die serverweite Statistik (aggregiert über alle Spieler).
  final ValueChanged<String>? onOpenServer;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    if (data.sources.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: DesignCard(
          child: DesignText(
            'Noch keine Server- oder Weltdaten.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final source in data.sources) ...<Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
            child: _SourceCard(
              source: source,
              timezone: timezone,
              onTap: onOpenServer == null
                  ? null
                  : () => onOpenServer!(source.serverId),
            ),
          ),
          SizedBox(height: tokens.spaceMd),
        ],
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          child: DesignText(
            'Vanilla-Statistiken gelten pro Welt; die Übersicht summiert alle '
            'Quellen.',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.timezone, this.onTap});

  final MinecraftStatsSource source;
  final String timezone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final collectedAt = source.collectedAt;
    return DesignCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DesignText(
                  '${source.serverId} · ${source.world}',
                  style: DesignTextStyle.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null) ...<Widget>[
                SizedBox(width: tokens.spaceXs),
                Icon(Icons.chevron_right_rounded, color: tokens.textLow),
              ],
            ],
          ),
          if (collectedAt != null) ...<Widget>[
            SizedBox(height: tokens.spaceXs),
            DesignText(
              'Stand: ${formatDateTimeInZone(parseApiInstant(collectedAt), timezone)}',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
          SizedBox(height: tokens.spaceMd),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 480 ? 3 : 2;
              final width =
                  (constraints.maxWidth - tokens.spaceSm * (columns - 1)) /
                  columns;
              final metrics = <Widget>[
                _metric(
                  context,
                  'Spielzeit',
                  formatTicksAsDuration(
                    source.value('minecraft:custom', 'minecraft:play_time'),
                  ),
                ),
                _metric(
                  context,
                  'Tode',
                  formatInt(
                    source.value('minecraft:custom', 'minecraft:deaths'),
                  ),
                ),
                _metric(
                  context,
                  'Mobs',
                  formatInt(
                    source.value('minecraft:custom', 'minecraft:mob_kills'),
                  ),
                ),
                _metric(
                  context,
                  'Blöcke',
                  formatInt(source.total('minecraft:mined')),
                ),
                _metric(
                  context,
                  'Distanz',
                  formatCentimeters(source.distanceCm),
                ),
              ];
              return Wrap(
                spacing: tokens.spaceSm,
                runSpacing: tokens.spaceSm,
                children: <Widget>[
                  for (final metric in metrics)
                    SizedBox(width: width, child: metric),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DesignText(
          value,
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        DesignText(label, style: DesignTextStyle.label, color: tokens.textLow),
      ],
    );
  }
}
