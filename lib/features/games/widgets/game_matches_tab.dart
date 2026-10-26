import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/game_models.dart';
import '../utils/game_format.dart';
import 'game_result_badge.dart';

/// Match-History (max. 20, neueste zuerst).
class GameMatchesTab extends StatelessWidget {
  const GameMatchesTab({
    required this.matches,
    required this.timezone,
    super.key,
  });

  final List<DeadlockMatch> matches;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    if (matches.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceXl),
        child: DesignText(
          'Noch keine Matches im Cache.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final match in matches) ...<Widget>[
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    DesignAvatar(
                      imageUrl: match.heroIconUrl,
                      name: match.displayName,
                      size: 40,
                    ),
                    SizedBox(width: tokens.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          DesignText(
                            match.displayName,
                            style: DesignTextStyle.body,
                          ),
                          SizedBox(height: tokens.spaceXs),
                          DesignText(
                            _subtitle(match),
                            style: DesignTextStyle.label,
                            color: tokens.textLow,
                          ),
                        ],
                      ),
                    ),
                    GameResultBadge(outcome: match.outcome),
                  ],
                ),
                SizedBox(height: tokens.spaceMd),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _metric(
                        context,
                        'K / D / A',
                        '${match.kills} / ${match.deaths} / ${match.assists}',
                      ),
                    ),
                    Expanded(
                      child: _metric(
                        context,
                        'KDA',
                        formatDecimal(match.kda, digits: 2),
                      ),
                    ),
                    Expanded(
                      child: _metric(
                        context,
                        'Dauer',
                        formatMatchDuration(match.matchDurationSeconds),
                      ),
                    ),
                    Expanded(
                      child: _metric(
                        context,
                        'Netto/Min.',
                        formatInt(match.netWorthPerMin.round()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spaceMd),
        ],
      ],
    );
  }

  String _subtitle(DeadlockMatch match) {
    final parts = <String>[];
    if (match.startTime != null) {
      parts.add(
        formatDateTimeInZone(parseApiInstant(match.startTime!), timezone),
      );
    }
    final mode = match.gameModeLabel;
    if (mode != null) parts.add(mode);
    if (match.heroLevel > 0) parts.add('Level ${match.heroLevel}');
    return parts.join(' · ');
  }

  Widget _metric(BuildContext context, String label, String value) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DesignText(
          value,
          style: DesignTextStyle.body,
          color: tokens.textHigh,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
