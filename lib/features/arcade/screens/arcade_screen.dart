import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/arcade_models.dart';

/// Übersicht der selbst gehosteten Arcade-Browser-Spiele.
///
/// „Spielen“ stellt über `POST /arcade/games/{slug}/session` ein kurzlebiges
/// Session-Token aus und öffnet die gelieferte `playUrl` im Browser. Das
/// Spiel liest das Token aus dem URL-Fragment und meldet seine Scores selbst.
class ArcadeScreen extends StatefulWidget {
  const ArcadeScreen({super.key});

  @override
  State<ArcadeScreen> createState() => _ArcadeScreenState();
}

class _ArcadeScreenState extends State<ArcadeScreen> {
  List<ArcadeGame> _games = const <ArcadeGame>[];
  final Set<String> _starting = <String>{};
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
      final games = await AppScope.of(context).arcade.listGames();
      if (!mounted) return;
      setState(() {
        _games = games;
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load arcade games',
        error: e,
        stackTrace: st,
        name: 'arcade',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Spiele konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _play(ArcadeGame game) async {
    if (_starting.contains(game.slug)) return;
    setState(() => _starting.add(game.slug));
    try {
      final session = await AppScope.of(context).arcade.startSession(game.slug);
      final uri = Uri.tryParse(session.playUrl);
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showError();
      }
    } catch (e, st) {
      developer.log(
        'Failed to start arcade game',
        error: e,
        stackTrace: st,
        name: 'arcade',
      );
      _showError();
    } finally {
      if (mounted) setState(() => _starting.remove(game.slug));
    }
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Spiel konnte nicht gestartet werden.')),
    );
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
                'Spiele, die direkt im Browser laufen. Deine Bestleistungen '
                'werden über dein Beyond-Konto gespeichert.',
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
            ),
            SizedBox(height: tokens.spaceMd),
            if (_games.isEmpty)
              Padding(
                padding: EdgeInsets.all(tokens.spaceXl),
                child: DesignText(
                  'Zurzeit sind keine Spiele verfügbar.',
                  style: DesignTextStyle.body,
                  color: tokens.textLow,
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final game in _games)
                _GameCard(
                  game: game,
                  starting: _starting.contains(game.slug),
                  onPlay: () => _play(game),
                ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.starting,
    required this.onPlay,
  });

  final ArcadeGame game;
  final bool starting;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final better = game.scoreDirection == ScoreDirection.desc
        ? 'mehr ist besser'
        : 'weniger ist besser';

    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DesignText(game.title, style: DesignTextStyle.subtitle),
              ),
              Icon(Icons.sports_esports_rounded, color: tokens.textLow),
            ],
          ),
          if (game.description != null) ...<Widget>[
            SizedBox(height: tokens.spaceXs),
            DesignText(
              game.description!,
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          ],
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Wertung: $better',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceLg),
          DesignButton(
            label: 'Spielen',
            icon: Icons.play_arrow_rounded,
            loading: starting,
            fullWidth: true,
            onPressed: starting ? null : onPlay,
          ),
        ],
      ),
    );
  }
}
