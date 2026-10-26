import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/game_catalog.dart';
import '../models/game_models.dart';
import '../utils/game_error_messages.dart';
import '../utils/steam_id.dart';

/// Verwaltet die eigenen verknüpften Spiele-Accounts.
class ManageGamesScreen extends StatefulWidget {
  const ManageGamesScreen({super.key});

  @override
  State<ManageGamesScreen> createState() => _ManageGamesScreenState();
}

class _ManageGamesScreenState extends State<ManageGamesScreen> {
  List<GameAccount> _accounts = const <GameAccount>[];
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
      final accounts = await AppScope.of(context).games.listMine();
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load game accounts',
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

  Future<void> _link(GameDefinition game) async {
    final result = await showDesignSheet<GameAccount>(
      context: context,
      child: _LinkGameSheet(game: game),
    );
    if (result == null || !mounted) return;
    await _load();
  }

  Future<void> _unlink(GameDefinition game, GameAccount account) async {
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: _UnlinkGameSheet(game: game, account: account),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AppScope.of(context).games.unlink(game.slug);
      if (!mounted) return;
      await _load();
    } catch (e, st) {
      developer.log(
        'Failed to unlink game account',
        error: e,
        stackTrace: st,
        name: 'games',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(gameErrorMessage(e))));
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
            title: 'Spiele',
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
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spaceLg,
                          ),
                          child: DesignText(
                            'Verknüpfe deine Spiele-Accounts, um Statistiken '
                            'anzusehen und dich mit anderen zu vergleichen. '
                            'Die Verknüpfung und die Statistiken sind für alle '
                            'angemeldeten Beyond-Nutzer sichtbar.',
                            style: DesignTextStyle.body,
                            color: tokens.textLow,
                          ),
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
                                DesignButton(
                                  label: 'Erneut versuchen',
                                  variant: DesignButtonVariant.outlined,
                                  onPressed: _load,
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: tokens.spaceMd),
                        for (final game in gameCatalog)
                          _GameAccountCard(
                            game: game,
                            account: _accountFor(game.slug),
                            onLink: () => _link(game),
                            onUnlink: () =>
                                _unlink(game, _accountFor(game.slug)!),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GameAccountCard extends StatelessWidget {
  const _GameAccountCard({
    required this.game,
    required this.account,
    required this.onLink,
    required this.onUnlink,
  });

  final GameDefinition game;
  final GameAccount? account;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final linked = account != null;

    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (linked)
                DesignAvatar(
                  imageUrl: account!.avatarUrl,
                  name: account!.displayName ?? game.name,
                  size: 48,
                )
              else
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
                          ? (account!.displayName ?? 'Steam-Account')
                          : 'Nicht verknüpft',
                      style: DesignTextStyle.body,
                      color: linked ? tokens.textHigh : tokens.textLow,
                    ),
                    if (linked) ...<Widget>[
                      SizedBox(height: tokens.spaceXs),
                      DesignText(
                        'Steam-ID ${account!.accountId}'
                        '${account!.lastSyncedAt != null ? ' · Zuletzt synchronisiert ${formatRelativeDate(account!.lastSyncedAt!)}' : ''}',
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceLg),
          Wrap(
            spacing: tokens.spaceSm,
            runSpacing: tokens.spaceSm,
            children: <Widget>[
              DesignButton(
                label: linked ? 'Steam-ID ändern' : 'Verknüpfen',
                icon: linked ? Icons.edit_rounded : Icons.add_link_rounded,
                variant: linked
                    ? DesignButtonVariant.outlined
                    : DesignButtonVariant.filled,
                onPressed: onLink,
              ),
              if (linked)
                DesignButton(
                  label: 'Verknüpfung lösen',
                  variant: DesignButtonVariant.ghost,
                  onPressed: onUnlink,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sheet zum Verknüpfen/Ändern einer Steam-ID.
class _LinkGameSheet extends StatefulWidget {
  const _LinkGameSheet({required this.game});

  final GameDefinition game;

  @override
  State<_LinkGameSheet> createState() => _LinkGameSheetState();
}

class _LinkGameSheetState extends State<_LinkGameSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final accountId = normalizeSteamId(_controller.text);
    if (accountId == null) {
      setState(() {
        _error =
            'Bitte gib eine gültige SteamID3 (max. 10 Ziffern) oder '
            'SteamID64 ein.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final account = await AppScope.of(
        context,
      ).games.link(widget.game.slug, accountId);
      if (!mounted) return;
      Navigator.of(context).pop(account);
    } catch (e, st) {
      developer.log(
        'Failed to link game account',
        error: e,
        stackTrace: st,
        name: 'games',
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = gameErrorMessage(e);
      });
    }
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
          DesignText(
            '${widget.game.name} verknüpfen',
            style: DesignTextStyle.subtitle,
          ),
          SizedBox(height: tokens.spaceXs),
          DesignText(
            'SteamID64 (beginnt mit 7656…) oder SteamID3/Account-ID '
            '(max. 10 Ziffern).',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceLg),
          DesignTextField(
            hint: 'z. B. 76561198139938901',
            controller: _controller,
            keyboardType: TextInputType.number,
          ),
          if (_error != null) ...<Widget>[
            SizedBox(height: tokens.spaceSm),
            DesignText(
              _error!,
              style: DesignTextStyle.label,
              color: tokens.danger,
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          Row(
            children: <Widget>[
              Expanded(
                child: DesignButton(
                  label: 'Abbrechen',
                  variant: DesignButtonVariant.outlined,
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignButton(
                  label: 'Speichern',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bestätigungs-Sheet für das Lösen einer Verknüpfung.
class _UnlinkGameSheet extends StatelessWidget {
  const _UnlinkGameSheet({required this.game, required this.account});

  final GameDefinition game;
  final GameAccount account;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const DesignText('Verknüpfung lösen', style: DesignTextStyle.subtitle),
        SizedBox(height: tokens.spaceXs),
        DesignText(
          '${game.name} · ${account.displayName ?? account.accountId}',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
        SizedBox(height: tokens.spaceLg),
        const DesignDivider(),
        SizedBox(height: tokens.spaceLg),
        DesignText(
          'Die Verknüpfung und die gecachten Statistiken werden entfernt. '
          'Du kannst die Steam-ID jederzeit erneut hinterlegen.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
        SizedBox(height: tokens.spaceLg),
        Row(
          children: <Widget>[
            Expanded(
              child: DesignButton(
                label: 'Abbrechen',
                variant: DesignButtonVariant.outlined,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: DesignButton(
                label: 'Verknüpfung lösen',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
