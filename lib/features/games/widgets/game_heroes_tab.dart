import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_metric_bar.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../models/game_models.dart';
import '../utils/game_format.dart';

enum _HeroSort { matches, winRate, kda }

/// Helden-Statistiken mit Sortierung nach Spielen, Winrate oder KDA.
class GameHeroesTab extends StatefulWidget {
  const GameHeroesTab({
    required this.heroes,
    required this.timezone,
    super.key,
  });

  final List<DeadlockHeroStat> heroes;
  final String timezone;

  @override
  State<GameHeroesTab> createState() => _GameHeroesTabState();
}

class _GameHeroesTabState extends State<GameHeroesTab> {
  _HeroSort _sort = _HeroSort.matches;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    if (widget.heroes.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceXl),
        child: DesignText(
          'Noch keine Helden-Statistiken.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
          textAlign: TextAlign.center,
        ),
      );
    }

    final heroes = [...widget.heroes]..sort(_compare);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
          child: Wrap(
            spacing: tokens.spaceSm,
            runSpacing: tokens.spaceXs,
            children: <Widget>[
              for (final sort in _HeroSort.values)
                DesignChip(
                  label: _sortLabel(sort),
                  selected: sort == _sort,
                  onTap: () => setState(() => _sort = sort),
                ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceMd),
        for (final hero in heroes) ...<Widget>[
          _HeroCard(hero: hero, timezone: widget.timezone),
          SizedBox(height: tokens.spaceMd),
        ],
      ],
    );
  }

  int _compare(DeadlockHeroStat a, DeadlockHeroStat b) {
    return switch (_sort) {
      _HeroSort.matches => b.matchesPlayed.compareTo(a.matchesPlayed),
      _HeroSort.winRate => b.winRate.compareTo(a.winRate),
      _HeroSort.kda => b.kda.compareTo(a.kda),
    };
  }

  String _sortLabel(_HeroSort sort) => switch (sort) {
    _HeroSort.matches => 'Nach Spielen',
    _HeroSort.winRate => 'Nach Winrate',
    _HeroSort.kda => 'Nach KDA',
  };
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.hero, required this.timezone});

  final DeadlockHeroStat hero;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final lastPlayed = hero.lastPlayed;
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              DesignAvatar(
                imageUrl: hero.heroIconUrl,
                name: hero.displayName,
                size: 40,
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DesignText(
                      hero.displayName,
                      style: DesignTextStyle.subtitle,
                    ),
                    SizedBox(height: tokens.spaceXs),
                    DesignText(
                      '${hero.matchesPlayed} Spiele · '
                      '${hero.wins} S / ${hero.losses} N'
                      '${lastPlayed != null ? ' · zuletzt ${formatDateInZone(parseApiInstant(lastPlayed), timezone)}' : ''}',
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMd),
          DesignMetricBar(
            label: 'Winrate',
            fraction: hero.winRate,
            valueText: formatPercent(hero.winRate),
            color: tokens.success,
          ),
          SizedBox(height: tokens.spaceMd),
          Row(
            children: <Widget>[
              Expanded(
                child: _metric(
                  context,
                  'KDA',
                  formatDecimal(hero.kda, digits: 2),
                ),
              ),
              Expanded(
                child: _metric(
                  context,
                  'Netto/Min.',
                  hero.networthPerMin == null
                      ? '–'
                      : formatInt(hero.networthPerMin!.round()),
                ),
              ),
              Expanded(
                child: _metric(
                  context,
                  'Schaden/Min.',
                  hero.damagePerMin == null
                      ? '–'
                      : formatInt(hero.damagePerMin!.round()),
                ),
              ),
              Expanded(
                child: _metric(
                  context,
                  'Genauigkeit',
                  hero.accuracy == null ? '–' : formatPercent(hero.accuracy!),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceXs),
          DesignText(
            'Spielzeit ${formatPlayedMinutes(hero.timePlayedSeconds)}'
            '${hero.endingLevel != null ? ' · Endlevel ${formatDecimal(hero.endingLevel!, digits: 1)}' : ''}',
            style: DesignTextStyle.label,
            color: tokens.textLow,
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
        DesignText(value, style: DesignTextStyle.body, color: tokens.textHigh),
        DesignText(
          label,
          style: DesignTextStyle.label,
          color: tokens.textLow,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
