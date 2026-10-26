import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/game_catalog.dart';
import '../models/game_models.dart';
import '../utils/game_error_messages.dart';

/// Übersicht der unterstützten Spiele mit den eigenen Statistiken.
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  List<GameAccount> _accounts = const <GameAccount>[];
  final Map<String, GameStatsResponse> _stats = <String, GameStatsResponse>{};
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scope = AppScope.of(context);
      final userId = scope.auth.userId;
      final accounts = await scope.games.listMine();
      final stats = <String, GameStatsResponse>{};
      if (userId != null) {
        for (final account in accounts) {
          try {
            stats[account.game] = await scope.games.stats(account.game, userId);
          } catch (e, st) {
            developer.log(
              'Failed to load own game stats',
              error: e,
              stackTrace: st,
              name: 'games',
            );
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _stats
          ..clear()
          ..addAll(stats);
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load games',
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

  GameAccount? _accountFor(String game) {
    for (final account in _accounts) {
      if (account.game == game) return account;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return DesignSurface(
        child: Center(child: CircularProgressIndicator(color: tokens.primary)),
      );
    }

    if (_error != null) {
      return DesignSurface(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            children: <Widget>[
              SizedBox(height: tokens.spaceXxl),
              Icon(Icons.error_outline_rounded, size: 48, color: tokens.danger),
              SizedBox(height: tokens.spaceSm),
              DesignText(
                _error!,
                style: DesignTextStyle.body,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spaceLg),
              Center(
                child: DesignButton(
                  label: 'Erneut versuchen',
                  variant: DesignButtonVariant.outlined,
                  onPressed: _load,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DesignSurface(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.only(bottom: tokens.spaceXl),
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
              child: DesignText(
                'Vergleiche deine Spielstatistiken mit anderen Beyond-Nutzern. '
                'Die Daten stammen aus den öffentlichen Spiel-APIs und werden '
                'stündlich aktualisiert.',
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
            ),
            SizedBox(height: tokens.spaceMd),
            for (final game in gameCatalog)
              _GameOverviewCard(
                game: game,
                account: _accountFor(game.slug),
                stats: _stats[game.slug],
                onOpen: () => context.push('/spiele/${game.slug}'),
                onManage: () => context.push('/einstellungen/spiele'),
              ),
            SizedBox(height: tokens.spaceLg),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
              child: DesignButton(
                label: 'Spiele-Accounts verwalten',
                icon: Icons.settings_rounded,
                variant: DesignButtonVariant.outlined,
                fullWidth: true,
                onPressed: () => context.push('/einstellungen/spiele'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverviewCard extends StatelessWidget {
  const _GameOverviewCard({
    required this.game,
    required this.account,
    required this.stats,
    required this.onOpen,
    required this.onManage,
  });

  final GameDefinition game;
  final GameAccount? account;
  final GameStatsResponse? stats;
  final VoidCallback onOpen;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final linked = account != null;
    final summary = stats?.stats == null
        ? null
        : GameSummary.fromStats(stats!.stats!);
    final rank = stats?.stats?.rank;

    return DesignCard(
      onTap: linked ? onOpen : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tokens.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(game.icon, color: tokens.primary, size: 24),
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DesignText(game.name, style: DesignTextStyle.subtitle),
                    SizedBox(height: tokens.spaceXs),
                    DesignText(
                      linked
                          ? (rank?.label ?? 'Noch keine Rangdaten')
                          : 'Nicht verknüpft',
                      style: DesignTextStyle.body,
                      color: linked ? tokens.textHigh : tokens.textLow,
                    ),
                  ],
                ),
              ),
              if (linked)
                Icon(Icons.chevron_right_rounded, color: tokens.textLow),
            ],
          ),
          if (linked && summary != null) ...<Widget>[
            SizedBox(height: tokens.spaceLg),
            Row(
              children: <Widget>[
                Expanded(
                  child: _value(context, 'Spiele', '${summary.matches}'),
                ),
                Expanded(
                  child: _value(
                    context,
                    'Winrate',
                    '${(summary.winRate * 100).toStringAsFixed(0)} %',
                  ),
                ),
                Expanded(
                  child: _value(context, 'KDA', summary.kda.toStringAsFixed(2)),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              _syncLine(stats, AppScope.of(context).timeZones.effective),
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
          if (!linked) ...<Widget>[
            SizedBox(height: tokens.spaceLg),
            DesignButton(
              label: 'Steam-ID verknüpfen',
              icon: Icons.add_link_rounded,
              onPressed: onManage,
            ),
          ] else if (stats?.stats == null) ...<Widget>[
            SizedBox(height: tokens.spaceSm),
            DesignText(
              'Die Statistiken erscheinen nach der nächsten Synchronisierung.',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
        ],
      ),
    );
  }

  Widget _value(BuildContext context, String label, String value) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DesignText(
          value,
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        DesignText(label, style: DesignTextStyle.label, color: tokens.textLow),
      ],
    );
  }

  String _syncLine(GameStatsResponse? stats, String timeZone) {
    final parts = <String>['Steam-ID ${account!.accountId}'];
    if (account!.lastSyncedAt != null) {
      parts.add('synchronisiert ${formatRelativeDate(account!.lastSyncedAt!)}');
    }
    if (stats?.nextRefreshAt != null) {
      final next = formatTimeInZone(
        parseApiInstant(stats!.nextRefreshAt!),
        timeZone,
      );
      parts.add('nächste Aktualisierung $next');
    }
    return parts.join(' · ');
  }
}
