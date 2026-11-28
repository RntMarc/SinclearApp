import 'dart:developer' as developer;

import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/composite/design_tab_bar.dart';
import '../../../design/widgets/composite/design_picker_field.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/game_catalog.dart';
import '../models/game_models.dart';
import '../utils/game_account.dart';
import '../utils/game_error_messages.dart';
import '../utils/game_format.dart';
import '../widgets/game_heroes_tab.dart';
import '../widgets/game_matches_tab.dart';
import '../widgets/game_overview_tab.dart';
import '../widgets/minecraft_overview_tab.dart';
import '../widgets/minecraft_sources_tab.dart';
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
  final TextEditingController _statsSearch = TextEditingController();
  String _statsQuery = '';

  /// Server-Filter für Übersicht und Statistiken (null = global).
  String? _serverFilter;

  bool get _isMinecraft => widget.game == 'minecraft';

  @override
  void dispose() {
    _statsSearch.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameStatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      _tab = _StatsTab.overview;
      _statsQuery = '';
      _serverFilter = null;
      _statsSearch.clear();
    }
    if (oldWidget.userId != widget.userId || oldWidget.game != widget.game) {
      _serverFilter = null;
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
      final account = await _loadGameAccount(scope, targetUserId);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _displayName =
            stats.minecraft?.playerName ?? account?.displayName ?? 'Spieler';
        _imageUrl = account?.avatarUrl;
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
        _error = gameErrorMessage(e, game: widget.game);
      });
    }
  }

  /// Anzeigename und Avatar des verknüpften Accounts.
  ///
  /// Die Statistik-Antwort enthält nur die `accountId`; die Profildaten kommen
  /// laut API aus `/user/{userId}/games`.
  Future<GameAccount?> _loadGameAccount(AppScope scope, String userId) async {
    try {
      final accounts = await scope.games.listForUser(userId);
      for (final account in accounts) {
        if (account.game == widget.game) return account;
      }
    } catch (e, st) {
      // Statistiken bleiben nutzbar, auch wenn das Profil nicht lädt.
      developer.log(
        'Failed to load game account',
        error: e,
        stackTrace: st,
        name: 'games',
      );
    }
    return null;
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
    context.go('/karriere/${widget.game}?spieler=${player.userId}');
  }

  Future<void> _openServer(String serverId) async {
    await context.push('/karriere/minecraft/server/$serverId');
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
      '/karriere/${widget.game}/vergleich'
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
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: <Widget>[
                        SliverToBoxAdapter(
                          child: _PlayerCard(
                            displayName: _displayName,
                            imageUrl: _imageUrl,
                            badgeLabel: _isMinecraft
                                ? 'Minecraft'
                                : (_stats?.stats?.rank?.label ??
                                      'Unkalibriert'),
                            badgeIconUrl: _isMinecraft
                                ? null
                                : _stats?.stats?.rank?.iconUrl,
                            accountIdLabel: gameAccountIdLabel(widget.game),
                            stats: _stats,
                            serverIds:
                                _stats?.minecraft?.serverIds ??
                                const <String>[],
                            serverFilter: _serverFilter,
                            onServerChanged: (value) =>
                                setState(() => _serverFilter = value),
                            onSwitch: _switchPlayer,
                            onCompare: _compare,
                          ),
                        ),
                        if (_error != null)
                          SliverToBoxAdapter(child: _errorState(context))
                        else if (_stats?.hasStats != true)
                          SliverToBoxAdapter(child: _emptyState(context))
                        else ...<Widget>[
                          SliverToBoxAdapter(child: _tabs(context)),
                          ..._contentSlivers(context),
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
    return DesignTabBar(
      index: _tab.index,
      onChanged: (index) => setState(() => _tab = _StatsTab.values[index]),
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceMd,
      ),
      items: _isMinecraft
          ? const <DesignTabBarItem>[
              DesignTabBarItem(
                icon: Icons.insights_rounded,
                label: 'Übersicht',
              ),
              DesignTabBarItem(icon: Icons.dns_rounded, label: 'Server'),
              DesignTabBarItem(
                icon: Icons.list_alt_rounded,
                label: 'Statistiken',
              ),
            ]
          : const <DesignTabBarItem>[
              DesignTabBarItem(
                icon: Icons.insights_rounded,
                label: 'Übersicht',
              ),
              DesignTabBarItem(icon: Icons.shield_rounded, label: 'Helden'),
              DesignTabBarItem(icon: Icons.history_rounded, label: 'Matches'),
            ],
    );
  }

  List<Widget> _contentSlivers(BuildContext context) {
    final timezone = AppScope.of(context).timeZones.effective;

    if (_isMinecraft) {
      final all = _stats!.minecraft!;
      final data = all.forServer(_serverFilter);
      return switch (_tab) {
        _StatsTab.overview when data.sources.isEmpty => _noSourceSlivers(
          context,
        ),
        _StatsTab.matches when data.sources.isEmpty => _noSourceSlivers(
          context,
        ),
        _StatsTab.overview => <Widget>[
          SliverToBoxAdapter(
            child: MinecraftOverviewTab(data: data, timezone: timezone),
          ),
        ],
        _StatsTab.heroes => <Widget>[
          SliverToBoxAdapter(
            child: MinecraftSourcesTab(
              data: all,
              timezone: timezone,
              onOpenServer: _openServer,
            ),
          ),
        ],
        _StatsTab.matches => _minecraftStatsSlivers(context, data),
      };
    }

    final data = _stats!.stats!;
    final summary = GameSummary.fromStats(data);
    return <Widget>[
      SliverToBoxAdapter(
        child: switch (_tab) {
          _StatsTab.overview => GameOverviewTab(
            data: data,
            summary: summary,
            timezone: timezone,
            onOpenHeroes: () => setState(() => _tab = _StatsTab.heroes),
          ),
          _StatsTab.heroes => GameHeroesTab(
            heroes: data.heroStats,
            timezone: timezone,
          ),
          _StatsTab.matches => GameMatchesTab(
            matches: data.matchHistory,
            timezone: timezone,
          ),
        },
      ),
    ];
  }

  /// Leerzustand, wenn für den gewählten Server (oder überhaupt) keine Quelle
  /// vorliegt.
  List<Widget> _noSourceSlivers(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final filtered = _serverFilter != null;
    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DesignText(
                  filtered
                      ? 'Auf diesem Server liegen keine Daten vor.'
                      : 'Es liegen noch keine Serverdaten vor.',
                  style: DesignTextStyle.body,
                  color: tokens.textLow,
                ),
                if (filtered) ...<Widget>[
                  SizedBox(height: tokens.spaceMd),
                  DesignButton(
                    label: 'Global anzeigen',
                    variant: DesignButtonVariant.outlined,
                    onPressed: () => setState(() => _serverFilter = null),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _minecraftStatsSlivers(
    BuildContext context,
    MinecraftStats data,
  ) {
    final tokens = DesignTheme.of(context);
    final items = _minecraftStatItems(data);
    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceLg,
            tokens.spaceLg,
            tokens.spaceSm,
          ),
          child: DesignTextField(
            hint: 'Statistik suchen',
            controller: _statsSearch,
            prefixIcon: Icons.search_rounded,
            onChanged: (value) => setState(() => _statsQuery = value),
          ),
        ),
      ),
      if (items.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: DesignText(
              'Keine Statistik passt zur Suche.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = items[index];
            if (item is String) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spaceLg,
                  tokens.spaceLg,
                  tokens.spaceLg,
                  tokens.spaceXs,
                ),
                child: DesignText(
                  minecraftCategoryLabel(item),
                  style: DesignTextStyle.subtitle,
                ),
              );
            }
            final entry = item as MinecraftStatEntry;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceLg,
                vertical: tokens.spaceXs,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: DesignText(
                      minecraftStatLabel(entry.stat),
                      style: DesignTextStyle.body,
                    ),
                  ),
                  SizedBox(width: tokens.spaceSm),
                  DesignText(
                    formatMinecraftStatValue(
                      entry.category,
                      entry.stat,
                      entry.value,
                    ),
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                ],
              ),
            );
          }, childCount: items.length),
        ),
      SliverToBoxAdapter(child: SizedBox(height: tokens.spaceXl)),
    ];
  }

  List<Object> _minecraftStatItems(MinecraftStats data) {
    final query = _statsQuery.trim().toLowerCase();
    final entries = data.allEntries.where((entry) {
      if (query.isEmpty) return true;
      return minecraftStatLabel(entry.stat).toLowerCase().contains(query) ||
          entry.stat.toLowerCase().contains(query) ||
          minecraftCategoryLabel(
            entry.category,
          ).toLowerCase().contains(query) ||
          entry.category.toLowerCase().contains(query);
    }).toList();

    final items = <Object>[];
    String? category;
    for (final entry in entries) {
      if (entry.category != category) {
        category = entry.category;
        items.add(category);
      }
      items.add(entry);
    }
    return items;
  }

  Widget _errorState(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
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
                  onPressed: () => context.push('/einstellungen/spiele'),
                ),
            ],
          ),
        ],
      ),
    );
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
                  ? (_isMinecraft
                        ? 'Dein Account ist verknüpft. Die Statistiken '
                              'erscheinen, sobald der Server Daten sendet.'
                        : 'Dein Account ist verknüpft. Die Statistiken werden '
                              'beim nächsten Cron-Lauf in den Cache geschrieben.')
                  : (_isMinecraft
                        ? 'Der Account ist verknüpft, aber es liegen noch keine '
                              'Minecraft-Statistiken vor.'
                        : 'Der Account ist verknüpft, aber es liegen noch keine '
                              'Statistiken im Cache.'),
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
    required this.badgeLabel,
    this.badgeIconUrl,
    required this.accountIdLabel,
    required this.stats,
    this.serverIds = const <String>[],
    this.serverFilter,
    required this.onServerChanged,
    required this.onSwitch,
    this.onCompare,
  });

  final String displayName;
  final String? imageUrl;
  final String badgeLabel;
  final String? badgeIconUrl;
  final String accountIdLabel;
  final GameStatsResponse? stats;

  /// Server des angesehenen Spielers (nur Minecraft).
  final List<String> serverIds;
  final String? serverFilter;
  final ValueChanged<String?> onServerChanged;
  final VoidCallback onSwitch;
  final VoidCallback? onCompare;

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
                        if (badgeIconUrl != null) ...<Widget>[
                          DesignAvatar(
                            imageUrl: badgeIconUrl,
                            name: badgeLabel,
                            size: 20,
                          ),
                          SizedBox(width: tokens.spaceXs),
                        ],
                        Flexible(
                          child: DesignText(
                            badgeLabel,
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
              if (onCompare != null)
                DesignButton(
                  label: 'Vergleichen',
                  icon: Icons.compare_arrows_rounded,
                  onPressed: onCompare,
                ),
            ],
          ),
          if (serverIds.isNotEmpty) ...<Widget>[
            SizedBox(height: tokens.spaceMd),
            DesignPickerField(
              hint: 'Server',
              prefixIcon: Icons.dns_rounded,
              value: serverFilter ?? '',
              items: <DesignPickerItem>[
                const DesignPickerItem(
                  value: '',
                  label: 'Global (alle Server)',
                ),
                for (final serverId in serverIds)
                  DesignPickerItem(value: serverId, label: serverId),
              ],
              onChanged: (value) =>
                  onServerChanged(value.isEmpty ? null : value),
            ),
          ],
        ],
      ),
    );
  }

  String _syncLine(String timezone) {
    final parts = <String>[];
    if (stats?.accountId != null && stats!.accountId.isNotEmpty) {
      parts.add('$accountIdLabel ${stats!.accountId}');
    }
    final minecraft = stats?.minecraft;
    if (minecraft != null) {
      final count = minecraft.sources.length;
      parts.add('$count ${count == 1 ? 'Welt' : 'Welten'}');
    }
    final lastSynced = minecraft?.syncedAt ?? stats?.lastRefreshedAt;
    if (lastSynced != null) {
      parts.add('Stand: ${formatRelativeDate(lastSynced)}');
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
