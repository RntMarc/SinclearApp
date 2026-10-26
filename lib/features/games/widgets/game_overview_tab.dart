import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bar_chart.dart';
import '../../../design/widgets/composite/design_metric_bar.dart';
import '../../../design/widgets/composite/design_outcome_strip.dart';
import '../../../design/widgets/composite/design_stat_tile.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/game_models.dart';
import '../utils/game_format.dart';

/// Übersicht eines Spielerprofils: Kennzahlen, letzte Ergebnisse, Verlauf.
class GameOverviewTab extends StatelessWidget {
  const GameOverviewTab({
    required this.data,
    required this.summary,
    required this.timezone,
    super.key,
  });

  final DeadlockStats data;
  final GameSummary summary;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final rank = data.rank;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          child: _statGrid(context),
        ),
        SizedBox(height: tokens.spaceLg),
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const DesignText(
                'Letzte Spiele',
                style: DesignTextStyle.subtitle,
              ),
              SizedBox(height: tokens.spaceXs),
              DesignText(
                _recentLine(),
                style: DesignTextStyle.label,
                color: tokens.textLow,
              ),
              SizedBox(height: tokens.spaceMd),
              DesignOutcomeStrip(
                items: <DesignOutcomeItem>[
                  for (final match in summary.recentMatches)
                    _outcomeItem(match),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceLg),
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const DesignText(
                'Netto-Wert pro Minute',
                style: DesignTextStyle.subtitle,
              ),
              SizedBox(height: tokens.spaceXs),
              DesignText(
                _netWorthLine(),
                style: DesignTextStyle.label,
                color: tokens.textLow,
              ),
              SizedBox(height: tokens.spaceLg),
              DesignBarChart(
                bars: <DesignBar>[
                  for (final match in summary.recentMatches.reversed)
                    DesignBar(
                      value: match.netWorthPerMin,
                      color: match.outcome == MatchOutcome.win
                          ? tokens.success
                          : tokens.danger,
                      semanticLabel:
                          '${match.displayName}, '
                          '${_date(match.startTime)}: '
                          '${formatInt(match.netWorthPerMin.round())} '
                          'Netto-Wert pro Minute, '
                          '${_outcomeLabel(match.outcome)}',
                    ),
                ],
              ),
              SizedBox(height: tokens.spaceSm),
              Wrap(
                spacing: tokens.spaceSm,
                runSpacing: tokens.spaceXs,
                children: <Widget>[
                  DesignBadge(label: 'Sieg', color: tokens.success),
                  DesignBadge(label: 'Niederlage', color: tokens.danger),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceLg),
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const DesignText('Top-Helden', style: DesignTextStyle.subtitle),
              SizedBox(height: tokens.spaceMd),
              if (summary.heroes.isEmpty)
                DesignText(
                  'Noch keine Helden-Daten.',
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                )
              else
                for (final hero in summary.heroes.take(3))
                  Padding(
                    padding: EdgeInsets.only(bottom: tokens.spaceMd),
                    child: DesignMetricBar(
                      leading: Icon(
                        Icons.sports_esports_rounded,
                        size: 16,
                        color: tokens.primary,
                      ),
                      label: hero.displayName,
                      fraction: hero.winRate,
                      valueText:
                          '${formatPercent(hero.winRate)} · '
                          '${hero.matchesPlayed} Spiele',
                    ),
                  ),
            ],
          ),
        ),
        if (rank?.lastMatchStartAt != null) ...<Widget>[
          SizedBox(height: tokens.spaceLg),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
            child: DesignText(
              'Letztes gewertetes Match: '
              '${formatDateTimeInZone(parseApiInstant(rank!.lastMatchStartAt!), timezone)}',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ),
        ],
      ],
    );
  }

  Widget _statGrid(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final tiles = <Widget>[
      DesignStatTile(
        label: 'Rang',
        value: data.rank?.label ?? 'Unkalibriert',
        icon: Icons.military_tech_rounded,
        emphasis: true,
      ),
      DesignStatTile(
        label: 'Spiele',
        value: formatInt(summary.matches),
        icon: Icons.sports_esports_rounded,
      ),
      DesignStatTile(
        label: 'Winrate',
        value: formatPercent(summary.winRate),
        icon: Icons.percent_rounded,
      ),
      DesignStatTile(
        label: 'KDA',
        value: formatDecimal(summary.kda, digits: 2),
        icon: Icons.trending_up_rounded,
      ),
      DesignStatTile(
        label: 'Netto-Wert/Min.',
        value: formatInt(summary.netWorthPerMin.round()),
        icon: Icons.paid_rounded,
      ),
      DesignStatTile(
        label: 'Schaden/Min.',
        value: formatInt(summary.damagePerMin.round()),
        icon: Icons.local_fire_department_rounded,
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

  String _recentLine() {
    final matches = summary.recentMatches;
    if (matches.isEmpty) return 'Noch keine Matches im Cache.';
    return '${matches.length} Matches · '
        '${summary.recentWins} Siege · '
        '${summary.recentLosses} Niederlagen';
  }

  String _netWorthLine() {
    final matches = summary.recentMatches;
    if (matches.isEmpty) return 'Keine Match-Daten vorhanden.';
    final values = matches.map((match) => match.netWorthPerMin);
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    return 'Verlauf der letzten ${matches.length} Matches · '
        'Min. ${formatInt(min.round())} · Max. ${formatInt(max.round())}';
  }

  DesignOutcomeItem _outcomeItem(DeadlockMatch match) {
    final (label, short, tone) = switch (match.outcome) {
      MatchOutcome.win => ('Sieg', 'S', DesignOutcomeTone.positive),
      MatchOutcome.loss => ('Niederlage', 'N', DesignOutcomeTone.negative),
      MatchOutcome.penalized => ('Penalty', 'P', DesignOutcomeTone.neutral),
      MatchOutcome.notScored => (
        'Nicht gewertet',
        '–',
        DesignOutcomeTone.neutral,
      ),
      MatchOutcome.unknown => ('Unbekannt', '?', DesignOutcomeTone.neutral),
    };
    return DesignOutcomeItem(label: label, shortLabel: short, tone: tone);
  }

  String _date(String? iso) {
    if (iso == null) return 'unbekannt';
    return formatDateInZone(parseApiInstant(iso), timezone);
  }

  String _outcomeLabel(MatchOutcome outcome) => switch (outcome) {
    MatchOutcome.win => 'Sieg',
    MatchOutcome.loss => 'Niederlage',
    MatchOutcome.penalized => 'Penalty',
    MatchOutcome.notScored => 'Nicht gewertet',
    MatchOutcome.unknown => 'Unbekannt',
  };
}
