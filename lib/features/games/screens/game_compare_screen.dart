import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_comparison_table.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../user/models/user_models.dart';
import '../models/game_catalog.dart';
import '../models/game_models.dart';
import '../utils/game_error_messages.dart';
import '../utils/game_format.dart';
import '../widgets/player_picker_sheet.dart';

/// Stellt zwei Spieler anhand ihrer Kennzahlen gegenüber.
class GameCompareScreen extends StatefulWidget {
  const GameCompareScreen({
    required this.game,
    required this.userIds,
    super.key,
  });

  final String game;
  final List<String> userIds;

  @override
  State<GameCompareScreen> createState() => _GameCompareScreenState();
}

class _GameCompareScreenState extends State<GameCompareScreen> {
  List<GamePlayer> _players = const <GamePlayer>[];
  bool _loading = true;
  String? _error;

  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant GameCompareScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.userIds, widget.userIds) ||
        oldWidget.game != widget.game) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scope = AppScope.of(context);
      final ids = widget.userIds.take(2).toList();
      if (ids.length < 2) {
        setState(() {
          _loading = false;
          _error = 'Bitte wähle zwei Spieler zum Vergleichen aus.';
        });
        return;
      }

      final stats = await scope.games.batchStats(widget.game, ids);
      final byUser = <String, GameStatsResponse>{
        for (final entry in stats) entry.userId: entry,
      };
      final users = <String, UserBasePublic>{
        for (final user in await scope.user.listAll()) user.id: user,
      };

      final players = <GamePlayer>[];
      for (final id in ids) {
        final statsEntry = byUser[id];
        final user = users[id];
        if (statsEntry == null) continue;
        players.add(
          GamePlayer(
            userId: id,
            displayName: user?.displayName ?? 'Spieler',
            imageUrl: user?.image,
            stats: statsEntry,
          ),
        );
      }

      if (!mounted) return;
      if (players.length < 2) {
        setState(() {
          _loading = false;
          _error = 'Mindestens einer der Spieler hat keine Spieldaten.';
        });
        return;
      }
      setState(() {
        _players = players;
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load comparison',
        error: e,
        stackTrace: st,
        name: 'games',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = gameErrorMessage(e);
      });
    }
  }

  Future<void> _pickOpponent() async {
    if (_players.isEmpty) return;
    final first = _players.first;
    final player = await showGamePlayerPicker(
      context,
      game: widget.game,
      excludedUserIds: <String>{first.userId},
      title: 'Gegner wählen',
    );
    if (player == null || !mounted) return;
    context.go(
      '/spiele/${widget.game}/vergleich'
      '?userIds=${first.userId},${player.userId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final game = gameForSlug(widget.game);

    return DesignSurface(
      child: Column(
        children: <Widget>[
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'Vergleich',
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: tokens.primary),
                  )
                : _error != null
                ? _errorState(context)
                : _content(context, game?.name ?? widget.game),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return ListView(
      children: <Widget>[
        SizedBox(height: tokens.spaceXl),
        Icon(Icons.error_outline_rounded, size: 48, color: tokens.danger),
        SizedBox(height: tokens.spaceSm),
        DesignText(_error!, textAlign: TextAlign.center),
        SizedBox(height: tokens.spaceLg),
        Center(
          child: DesignButton(
            label: 'Erneut versuchen',
            variant: DesignButtonVariant.outlined,
            onPressed: _load,
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context, String title) {
    final tokens = DesignTheme.of(context);
    final left = _players[0];
    final right = _players[1];
    final leftSummary = left.summary;
    final rightSummary = right.summary;
    final shared = _sharedHeroes(left, right);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.only(bottom: tokens.spaceXl),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
            child: Row(
              children: <Widget>[
                Expanded(child: _playerTile(context, left)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm),
                  child: DesignText(
                    'VS',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
                Expanded(child: _playerTile(context, right)),
              ],
            ),
          ),
          SizedBox(height: tokens.spaceMd),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
            child: DesignText(title, style: DesignTextStyle.title),
          ),
          SizedBox(height: tokens.spaceMd),
          DesignCard(
            child: DesignComparisonTable(
              columns: <String>[left.displayName, right.displayName],
              rows: <DesignComparisonRow>[
                _row(
                  'Rang',
                  left.rank?.label ?? 'Unkalibriert',
                  right.rank?.label ?? 'Unkalibriert',
                  _rankValue(left.rank),
                  _rankValue(right.rank),
                ),
                _row(
                  'Spiele',
                  formatInt(leftSummary.matches),
                  formatInt(rightSummary.matches),
                  leftSummary.matches.toDouble(),
                  rightSummary.matches.toDouble(),
                ),
                _row(
                  'Winrate',
                  formatPercent(leftSummary.winRate),
                  formatPercent(rightSummary.winRate),
                  leftSummary.winRate,
                  rightSummary.winRate,
                ),
                _row(
                  'KDA',
                  formatDecimal(leftSummary.kda, digits: 2),
                  formatDecimal(rightSummary.kda, digits: 2),
                  leftSummary.kda,
                  rightSummary.kda,
                ),
                _row(
                  'Netto-Wert/Min.',
                  formatInt(leftSummary.netWorthPerMin.round()),
                  formatInt(rightSummary.netWorthPerMin.round()),
                  leftSummary.netWorthPerMin,
                  rightSummary.netWorthPerMin,
                ),
                _row(
                  'Schaden/Min.',
                  formatInt(leftSummary.damagePerMin.round()),
                  formatInt(rightSummary.damagePerMin.round()),
                  leftSummary.damagePerMin,
                  rightSummary.damagePerMin,
                ),
                _row(
                  'Genauigkeit',
                  formatPercent(leftSummary.accuracy),
                  formatPercent(rightSummary.accuracy),
                  leftSummary.accuracy,
                  rightSummary.accuracy,
                ),
                _row(
                  'Top-Held',
                  leftSummary.topHero?.displayName ?? '–',
                  rightSummary.topHero?.displayName ?? '–',
                ),
                _row(
                  'Letzte Spiele',
                  '${leftSummary.recentWins} S / ${leftSummary.recentLosses} N',
                  '${rightSummary.recentWins} S / ${rightSummary.recentLosses} N',
                  _recentWinRate(leftSummary),
                  _recentWinRate(rightSummary),
                ),
              ],
            ),
          ),
          if (shared.isNotEmpty) ...<Widget>[
            SizedBox(height: tokens.spaceLg),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
              child: const DesignText(
                'Gemeinsame Helden',
                style: DesignTextStyle.subtitle,
              ),
            ),
            SizedBox(height: tokens.spaceSm),
            DesignCard(
              child: DesignComparisonTable(
                columns: <String>[left.displayName, right.displayName],
                rows: <DesignComparisonRow>[
                  for (final entry in shared)
                    _row(
                      entry.heroName,
                      '${formatPercent(entry.leftWinRate)} (${entry.leftMatches})',
                      '${formatPercent(entry.rightWinRate)} (${entry.rightMatches})',
                      entry.leftWinRate,
                      entry.rightWinRate,
                    ),
                ],
              ),
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
            child: DesignButton(
              label: 'Anderen Spieler wählen',
              icon: Icons.group_rounded,
              variant: DesignButtonVariant.outlined,
              fullWidth: true,
              onPressed: _pickOpponent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerTile(BuildContext context, GamePlayer player) {
    final tokens = DesignTheme.of(context);
    final syncedAt = player.stats?.lastRefreshedAt;
    return Column(
      children: <Widget>[
        DesignAvatar(
          imageUrl: player.imageUrl,
          name: player.displayName,
          size: 64,
        ),
        SizedBox(height: tokens.spaceSm),
        DesignText(
          player.displayName,
          style: DesignTextStyle.body,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: tokens.spaceXs),
        DesignText(
          player.rank?.label ?? 'Unkalibriert',
          style: DesignTextStyle.label,
          color: tokens.primary,
          textAlign: TextAlign.center,
        ),
        if (syncedAt != null) ...<Widget>[
          SizedBox(height: tokens.spaceXs),
          DesignText(
            'Stand: ${formatRelativeDate(syncedAt)}',
            style: DesignTextStyle.label,
            color: tokens.textLow,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  DesignComparisonRow _row(
    String label,
    String leftValue,
    String rightValue, [
    double? leftSort,
    double? rightSort,
  ]) {
    return DesignComparisonRow(
      label: label,
      values: <String>[leftValue, rightValue],
      sortValues: leftSort == null && rightSort == null
          ? null
          : <double?>[leftSort, rightSort],
    );
  }

  double? _recentWinRate(GameSummary summary) {
    final total = summary.recentWins + summary.recentLosses;
    return total == 0 ? null : summary.recentWins / total;
  }

  double? _rankValue(DeadlockRank? rank) {
    if (rank == null) return null;
    return rank.tier + rank.subrank / 10;
  }

  List<_SharedHero> _sharedHeroes(GamePlayer left, GamePlayer right) {
    final rightHeroes = <int, DeadlockHeroStat>{
      for (final hero in right.stats?.stats?.heroStats ?? <DeadlockHeroStat>[])
        hero.heroId: hero,
    };
    final shared = <_SharedHero>[];
    for (final hero in left.stats?.stats?.heroStats ?? <DeadlockHeroStat>[]) {
      final other = rightHeroes[hero.heroId];
      if (other == null) continue;
      shared.add(
        _SharedHero(
          heroName: hero.displayName,
          leftMatches: hero.matchesPlayed,
          rightMatches: other.matchesPlayed,
          leftWinRate: hero.winRate,
          rightWinRate: other.winRate,
        ),
      );
    }
    shared.sort(
      (a, b) => (b.leftMatches + b.rightMatches).compareTo(
        a.leftMatches + a.rightMatches,
      ),
    );
    return shared.take(5).toList();
  }
}

class _SharedHero {
  const _SharedHero({
    required this.heroName,
    required this.leftMatches,
    required this.rightMatches,
    required this.leftWinRate,
    required this.rightWinRate,
  });

  final String heroName;
  final int leftMatches;
  final int rightMatches;
  final double leftWinRate;
  final double rightWinRate;
}
