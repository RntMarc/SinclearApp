import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/game_catalog.dart';
import '../models/game_models.dart';
import '../utils/game_error_messages.dart';
import '../widgets/game_heroes_tab.dart';
import '../widgets/game_matches_tab.dart';
import '../widgets/game_overview_tab.dart';
import '../widgets/player_picker_sheet.dart';

enum _StatsTab { overview, heroes, matches }

/// Statistiken eines Spielers für ein Spiel.
class GameStatsScreen extends StatefulWidget {
  const GameStatsScreen({required this.game, this.userId, super.key});

  final String game;
  final String? userId;

  @override
  State<GameStatsScreen> createState() => _GameStatsScreenState();
}

class _GameStatsScreenState extends State<GameStatsScreen> {
  GameStatsResponse? _stats;
  String _displayName = 'Spieler';
  String? _imageUrl;
  bool _loading = true;
  String? _error;
  bool _notLinked = false;
  bool _hasLoaded = false;
  _StatsTab _tab = _StatsTab.overview;

  @override
  void didUpdateWidget(covariant GameStatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.game != widget.game) {
      _load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notLinked = false;
      _stats = null;
    });
    final scope = AppScope.of(context);
    final targetUserId = widget.userId ?? scope.auth.userId;
    if (targetUserId == null) {
      setState(() {
        _loading = false;
        _error = 'Bitte melde dich an, um Statistiken zu sehen.';
      });
      return;
    }

    try {
      final stats = await scope.games.stats(widget.game, targetUserId);
      String? displayName;
      String? imageUrl;
      try {
        final user = await scope.user.get(targetUserId);
        displayName = user.base.displayName;
        imageUrl = user.base.image;
      } catch (e, st) {
        // Statistiken bleiben nutzbar, auch wenn das Profil nicht lädt.
        developer.log(
          'Failed to load game stats profile',
          error: e,
          stackTrace: st,
          name: 'games',
        );
      }
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _displayName = displayName ?? 'Spieler';
        _imageUrl = imageUrl;
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load game stats',
        error: e,
        stackTrace: st,
        name: 'games',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notLinked =
            e is ApiException && e.errorCode == 'game_account_not_found';
        _error = gameErrorMessage(e);
      });
    }
  }

  bool get _isSelf {
    final currentUserId = AppScope.of(context).auth.userId;
    return (widget.userId ?? currentUserId) == currentUserId;
  }

  Future<void> _switchPlayer() async {
    final targetUserId = widget.userId ?? AppScope.of(context).auth.userId;
    if (targetUserId == null) return;
    final player = await showGamePlayerPicker(
      context,
      game: widget.game,
      excludedUserIds: <String>{targetUserId},
    );
    if (player == null || !mounted) return;
    context.go('/spiele/${widget.game}?spieler=${player.userId}');
  }

  Future<void> _compare() async {
    final targetUserId = widget.userId ?? AppScope.of(context).auth.userId;
    if (targetUserId == null) return;
    final player = await showGamePlayerPicker(
      context,
      game: widget.game,
      excludedUserIds: <String>{targetUserId},
      title: 'Mit wem vergleichen?',
    );
    if (player == null || !mounted) return;
    context.push(
      '/spiele/${widget.game}/vergleich'
      '?userIds=$targetUserId,${player.userId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final game = gameForSlug(widget.game);
    final title = game?.name ?? widget.game;

    return DesignSurface(
      child: Column(
        children: <Widget>[
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: title,
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: tokens.primary),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: EdgeInsets.only(bottom: tokens.spaceXl),
                      children: <Widget>[
                        _PlayerCard(
                          displayName: _displayName,
                          imageUrl: _imageUrl,
                          rank: _stats?.stats?.rank,
                          stats: _stats,
                          onSwitch: _switchPlayer,
                          onCompare: _compare,
                        ),
                        if (_error != null)
                          Padding(
                            padding: EdgeInsets.all(tokens.spaceLg),
                            child: Column(
                              children: <Widget>[
                                DesignText(
                                  _error!,
                                  style: DesignTextStyle.body,
                                  color: tokens.danger,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: tokens.spaceSm),
                                Wrap(
                                  spacing: tokens.spaceSm,
                                  runSpacing: tokens.spaceSm,
                                  alignment: WrapAlignment.center,
                                  children: <Widget>[
                                    DesignButton(
                                      label: 'Erneut versuchen',
                                      variant: DesignButtonVariant.outlined,
                                      onPressed: _load,
                                    ),
                                    if (_notLinked && _isSelf)
                                      DesignButton(
                                        label: 'Account verknüpfen',
                                        onPressed: () => context.push(
                                          '/einstellungen/spiele',
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        else if (_stats?.stats == null)
                          _emptyState(context)
                        else ...<Widget>[
                          _tabs(context),
                          SizedBox(height: tokens.spaceMd),
                          _tabContent(context, _stats!.stats!),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabs(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
      child: Wrap(
        spacing: tokens.spaceSm,
        runSpacing: tokens.spaceXs,
        children: <Widget>[
          DesignChip(
            label: 'Übersicht',
            selected: _tab == _StatsTab.overview,
            onTap: () => setState(() => _tab = _StatsTab.overview),
          ),
          DesignChip(
            label: 'Helden',
            selected: _tab == _StatsTab.heroes,
            onTap: () => setState(() => _tab = _StatsTab.heroes),
          ),
          DesignChip(
            label: 'Matches',
            selected: _tab == _StatsTab.matches,
            onTap: () => setState(() => _tab = _StatsTab.matches),
          ),
        ],
      ),
    );
  }

  Widget _tabContent(BuildContext context, DeadlockStats data) {
    final timezone = AppScope.of(context).timeZones.effective;
    final summary = GameSummary.fromStats(data);
    return switch (_tab) {
      _StatsTab.overview => GameOverviewTab(
        data: data,
        summary: summary,
        timezone: timezone,
      ),
      _StatsTab.heroes => GameHeroesTab(
        heroes: data.heroStats,
        timezone: timezone,
      ),
      _StatsTab.matches => GameMatchesTab(
        matches: data.matchHistory,
        timezone: timezone,
      ),
    };
  }

  Widget _emptyState(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: DesignCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const DesignText(
              'Noch keine Statistiken',
              style: DesignTextStyle.subtitle,
            ),
            SizedBox(height: tokens.spaceXs),
            DesignText(
              _isSelf
                  ? 'Dein Account ist verknüpft. Die Statistiken werden beim '
                        'nächsten Cron-Lauf in den Cache geschrieben.'
                  : 'Der Account ist verknüpft, aber es liegen noch keine '
                        'Statistiken im Cache.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
            if (_isSelf) ...<Widget>[
              SizedBox(height: tokens.spaceLg),
              DesignButton(
                label: 'Account verwalten',
                variant: DesignButtonVariant.outlined,
                onPressed: () => context.push('/einstellungen/spiele'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.displayName,
    required this.imageUrl,
    required this.rank,
    required this.stats,
    required this.onSwitch,
    required this.onCompare,
  });

  final String displayName;
  final String? imageUrl;
  final DeadlockRank? rank;
  final GameStatsResponse? stats;
  final VoidCallback onSwitch;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final timezone = AppScope.of(context).timeZones.effective;
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              DesignAvatar(imageUrl: imageUrl, name: displayName, size: 56),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DesignText(
                      displayName,
                      style: DesignTextStyle.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: tokens.spaceXs),
                    Row(
                      children: <Widget>[
                        if (rank?.iconUrl != null) ...<Widget>[
                          DesignAvatar(
                            imageUrl: rank!.iconUrl,
                            name: rank!.label,
                            size: 20,
                          ),
                          SizedBox(width: tokens.spaceXs),
                        ],
                        Flexible(
                          child: DesignText(
                            rank?.label ?? 'Unkalibriert',
                            style: DesignTextStyle.label,
                            color: tokens.primary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            _syncLine(timezone),
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceLg),
          Wrap(
            spacing: tokens.spaceSm,
            runSpacing: tokens.spaceSm,
            children: <Widget>[
              DesignButton(
                label: 'Spieler wechseln',
                icon: Icons.group_rounded,
                variant: DesignButtonVariant.outlined,
                onPressed: onSwitch,
              ),
              DesignButton(
                label: 'Vergleichen',
                icon: Icons.compare_arrows_rounded,
                onPressed: onCompare,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _syncLine(String timezone) {
    final parts = <String>[];
    if (stats?.accountId != null && stats!.accountId.isNotEmpty) {
      parts.add('Steam-ID ${stats!.accountId}');
    }
    if (stats?.lastRefreshedAt != null) {
      parts.add('Stand: ${formatRelativeDate(stats!.lastRefreshedAt!)}');
    }
    if (stats?.nextRefreshAt != null) {
      final next = formatTimeInZone(
        parseApiInstant(stats!.nextRefreshAt!),
        timezone,
      );
      parts.add('nächste Aktualisierung $next');
    }
    return parts.isEmpty ? 'Noch keine Cache-Daten' : parts.join(' · ');
  }
}
