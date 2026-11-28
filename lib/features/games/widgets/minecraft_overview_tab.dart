import 'package:material_ui/material_ui.dart';

import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_metric_bar.dart';
import '../../../design/widgets/composite/design_stat_tile.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/game_models.dart';
import '../utils/game_format.dart';

/// Übersicht der Minecraft-Statistiken: Kennzahlen und Top-Listen.
class MinecraftOverviewTab extends StatelessWidget {
  const MinecraftOverviewTab({
    required this.data,
    required this.timezone,
    this.footerLabel,
    super.key,
  });

  final MinecraftStats data;
  final String timezone;

  /// Ersetzt die Standard-Fußzeile („N Quellen · Stand …“).
  ///
  /// Die Server-Ansicht zeigt damit Spieler-/Weltenzahl statt Quellenzahl.
  final String? footerLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final sourceCount = data.sources.length;
    final syncedAt = data.syncedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          child: _statGrid(context),
        ),
        SizedBox(height: tokens.spaceLg),
        _topCard(
          context,
          title: 'Top-Mobs',
          entries: data.top('minecraft:killed'),
          icon: Icons.bug_report_rounded,
        ),
        SizedBox(height: tokens.spaceLg),
        _topCard(
          context,
          title: 'Top-Blöcke',
          entries: data.top('minecraft:mined'),
          icon: Icons.terrain_rounded,
        ),
        SizedBox(height: tokens.spaceLg),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          child: DesignText(
            footerLabel ??
                '$sourceCount ${sourceCount == 1 ? 'Quelle' : 'Quellen'}'
                    '${syncedAt == null ? '' : ' · Stand ${formatDateTimeInZone(parseApiInstant(syncedAt), timezone)}'}',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ),
      ],
    );
  }

  Widget _statGrid(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final tiles = <Widget>[
      DesignStatTile(
        label: 'Spielzeit',
        value: formatTicksAsDuration(data.playTimeTicks),
        icon: Icons.schedule_rounded,
        emphasis: true,
      ),
      DesignStatTile(
        label: 'Tode',
        value: formatInt(data.deaths),
        icon: Icons.dangerous_rounded,
      ),
      DesignStatTile(
        label: 'Mobs getötet',
        value: formatInt(data.mobKills),
        icon: Icons.bug_report_rounded,
      ),
      DesignStatTile(
        label: 'Blöcke abgebaut',
        value: formatInt(data.blocksMined),
        icon: Icons.terrain_rounded,
      ),
      DesignStatTile(
        label: 'Distanz',
        value: formatCentimeters(data.distanceCm),
        icon: Icons.route_rounded,
      ),
      DesignStatTile(
        label: 'Sprünge',
        value: formatInt(data.jumps),
        icon: Icons.north_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final width =
            (constraints.maxWidth - tokens.spaceSm * (columns - 1)) / columns;
        return Wrap(
          spacing: tokens.spaceSm,
          runSpacing: tokens.spaceSm,
          children: <Widget>[
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }

  Widget _topCard(
    BuildContext context, {
    required String title,
    required List<MinecraftStatEntry> entries,
    required IconData icon,
  }) {
    final tokens = DesignTheme.of(context);
    final maxValue = entries.isEmpty ? 0 : entries.first.value;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
      child: DesignCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DesignText(title, style: DesignTextStyle.subtitle),
            SizedBox(height: tokens.spaceMd),
            if (entries.isEmpty)
              DesignText(
                'Noch keine Daten.',
                style: DesignTextStyle.label,
                color: tokens.textLow,
              )
            else
              for (final entry in entries)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.spaceSm),
                  child: DesignMetricBar(
                    leading: Icon(icon, size: 16, color: tokens.primary),
                    label: minecraftStatLabel(entry.stat),
                    fraction: maxValue == 0 ? 0 : entry.value / maxValue,
                    valueText: formatMinecraftStatValue(
                      entry.category,
                      entry.stat,
                      entry.value,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
