import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../user/models/user_models.dart';
import '../models/game_models.dart';
import '../utils/game_error_messages.dart';
import '../utils/game_format.dart';

/// Öffnet die Spieler-Auswahl und liefert den gewählten Nutzer zurück.
Future<GamePlayer?> showGamePlayerPicker(
  BuildContext context, {
  required String game,
  required Set<String> excludedUserIds,
  String title = 'Spieler wählen',
}) {
  return showDesignSheet<GamePlayer>(
    context: context,
    child: _GamePlayerPickerSheet(
      game: game,
      excludedUserIds: excludedUserIds,
      title: title,
    ),
  );
}

class _GamePlayerPickerSheet extends StatefulWidget {
  const _GamePlayerPickerSheet({
    required this.game,
    required this.excludedUserIds,
    required this.title,
  });

  final String game;
  final Set<String> excludedUserIds;
  final String title;

  @override
  State<_GamePlayerPickerSheet> createState() => _GamePlayerPickerSheetState();
}

class _GamePlayerPickerSheetState extends State<_GamePlayerPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<GamePlayer> _players = const <GamePlayer>[];
  bool _loading = true;
  String? _error;
  String _query = '';
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
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scope = AppScope.of(context);
      final users = await scope.user.listAll();
      final candidates = users
          .where((user) => !widget.excludedUserIds.contains(user.id))
          .toList();
      final stats = await scope.games.batchStats(
        widget.game,
        candidates.map((user) => user.id).toList(),
      );
      final byUser = <String, GameStatsResponse>{
        for (final entry in stats) entry.userId: entry,
      };
      final players =
          <GamePlayer>[
            for (final user in candidates)
              if (byUser.containsKey(user.id))
                _playerFrom(user, byUser[user.id]!),
          ]..sort(
            (a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ),
          );
      if (!mounted) return;
      setState(() {
        _players = players;
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load game players',
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

  GamePlayer _playerFrom(UserBasePublic user, GameStatsResponse stats) {
    return GamePlayer(
      userId: user.id,
      displayName: user.displayName,
      imageUrl: user.image,
      stats: stats,
    );
  }

  List<GamePlayer> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _players;
    return _players
        .where((player) => player.displayName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DesignText(widget.title, style: DesignTextStyle.subtitle),
          SizedBox(height: tokens.spaceXs),
          DesignText(
            'Nur Beyond-Nutzer mit verknüpftem Account werden angezeigt.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceLg),
          DesignTextField(
            hint: 'Spieler suchen',
            controller: _search,
            prefixIcon: Icons.search_rounded,
            onChanged: (value) => setState(() => _query = value),
          ),
          SizedBox(height: tokens.spaceMd),
          if (_loading)
            Padding(
              padding: EdgeInsets.all(tokens.spaceXl),
              child: Center(
                child: CircularProgressIndicator(color: tokens.primary),
              ),
            )
          else if (_error != null)
            Column(
              children: <Widget>[
                DesignText(
                  _error!,
                  style: DesignTextStyle.body,
                  color: tokens.danger,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spaceSm),
                DesignButton(
                  label: 'Erneut versuchen',
                  variant: DesignButtonVariant.outlined,
                  onPressed: _load,
                ),
              ],
            )
          else if (_filtered.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceLg),
              child: DesignText(
                _players.isEmpty
                    ? 'Noch kein anderer Nutzer hat dieses Spiel verknüpft.'
                    : 'Kein Spieler passt zur Suche.',
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
            )
          else
            for (final player in _filtered)
              DesignListTile(
                leading: DesignAvatar(
                  imageUrl: player.imageUrl,
                  name: player.displayName,
                  size: 40,
                ),
                title: player.displayName,
                subtitle: _subtitle(player),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: tokens.textLow,
                ),
                padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
                onTap: () => Navigator.of(context).pop(player),
              ),
        ],
      ),
    );
  }

  String _subtitle(GamePlayer player) {
    final summary = player.summary;
    final rank = player.rank?.label;
    final parts = <String>[
      if (rank != null && rank.isNotEmpty) rank,
      if (summary.matches > 0) '${summary.matches} Spiele',
      if (summary.matches > 0) '${formatPercent(summary.winRate)} Winrate',
    ];
    return parts.isEmpty ? 'Noch keine Daten' : parts.join(' · ');
  }
}
