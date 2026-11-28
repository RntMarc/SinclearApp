import 'dart:developer' as developer;

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/minecraft_overview.dart';
import '../utils/game_error_messages.dart';
import '../utils/game_format.dart';
import '../widgets/minecraft_overview_tab.dart';

/// Serverweite Minecraft-Statistik über alle getrackten Spieler.
///
/// Die Daten stammen aus `GET /minecraft/sources?serverId=…` und enthalten auch
/// Spieler ohne verknüpftes Beyond-Profil.
class MinecraftServerScreen extends StatefulWidget {
  const MinecraftServerScreen({required this.serverId, super.key});

  final String serverId;

  @override
  State<MinecraftServerScreen> createState() => _MinecraftServerScreenState();
}

class _MinecraftServerScreenState extends State<MinecraftServerScreen> {
  /// Die API-Rangliste ist auf diesen Wert begrenzt; die Summen bleiben voll.
  static const int _rankingLimit = 100;

  MinecraftServerOverview? _server;
  bool _loading = true;
  bool _hasLoaded = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant MinecraftServerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverId != widget.serverId) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await AppScope.of(context).games.minecraftOverview(
        serverId: widget.serverId,
        limit: _rankingLimit,
      );
      if (!mounted) return;
      setState(() {
        _server = overview.servers.isEmpty ? null : overview.servers.first;
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load minecraft server overview',
        error: e,
        stackTrace: st,
        name: 'games',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = gameErrorMessage(e, game: 'minecraft');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Column(
        children: <Widget>[
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: widget.serverId,
          ),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: tokens.primary),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(bottom: tokens.spaceXl),
                      children: <Widget>[
                        if (_error != null)
                          _MessageCard(
                            message: _error!,
                            isError: true,
                            onRetry: _load,
                          )
                        else if (_server == null)
                          const _MessageCard(
                            message:
                                'Für diesen Server liegen noch keine '
                                'Statistiken vor.',
                          )
                        else ...<Widget>[
                          SizedBox(height: tokens.spaceMd),
                          _overview(context, _server!),
                          SizedBox(height: tokens.spaceLg),
                          _ranking(context, _server!),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _overview(BuildContext context, MinecraftServerOverview server) {
    final timezone = AppScope.of(context).timeZones.effective;
    final worlds = server.worlds.length;
    final parts = <String>[
      '${formatInt(server.playerCount)} Spieler',
      '$worlds ${worlds == 1 ? 'Welt' : 'Welten'}',
    ];
    final collectedAt = server.lastCollectedAt;
    if (collectedAt != null) {
      parts.add(
        'Stand ${formatDateTimeInZone(parseApiInstant(collectedAt), timezone)}',
      );
    }

    // ponytail: Rangliste fix nach Spielzeit; weitere Zähler brauchen einen
    // Picker, der sortCategory/sortStat an die API gibt.
    return MinecraftOverviewTab(
      data: server.asStats(),
      timezone: timezone,
      footerLabel: parts.join(' · '),
    );
  }

  Widget _ranking(BuildContext context, MinecraftServerOverview server) {
    final tokens = DesignTheme.of(context);
    if (server.ranking.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
      child: DesignCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const DesignText('Spieler', style: DesignTextStyle.subtitle),
            SizedBox(height: tokens.spaceXs),
            DesignText(
              'Rangliste nach Spielzeit'
              '${server.ranking.length >= _rankingLimit ? ' (Top $_rankingLimit)' : ''}',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
            SizedBox(height: tokens.spaceSm),
            for (
              var index = 0;
              index < server.ranking.length;
              index++
            ) ...<Widget>[
              if (index > 0) const DesignDivider(),
              _rankingTile(context, server.ranking[index]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rankingTile(BuildContext context, MinecraftRankingEntry entry) {
    final tokens = DesignTheme.of(context);
    final linkedUserId = entry.linkedUserId;
    return DesignListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 28,
            child: DesignText(
              '${entry.rank}',
              style: DesignTextStyle.label,
              color: entry.rank <= 3 ? tokens.primary : tokens.textLow,
            ),
          ),
          DesignAvatar(
            imageUrl: entry.avatarUrl,
            name: entry.displayName,
            size: 32,
          ),
        ],
      ),
      title: entry.displayName,
      subtitle: linkedUserId == null ? 'Nicht mit Beyond verknüpft' : null,
      trailing: DesignText(
        formatTicksAsDuration(entry.value),
        style: DesignTextStyle.body,
        color: tokens.textHigh,
      ),
      padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
      onTap: linkedUserId == null
          ? null
          : () => context.push('/karriere/minecraft?spieler=$linkedUserId'),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: DesignCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DesignText(
              message,
              style: DesignTextStyle.body,
              color: isError ? tokens.danger : tokens.textLow,
            ),
            if (onRetry != null) ...<Widget>[
              SizedBox(height: tokens.spaceMd),
              DesignButton(
                label: 'Erneut versuchen',
                variant: DesignButtonVariant.outlined,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
