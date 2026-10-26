import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../models/game_catalog.dart';

/// Rundes Spiel-Logo mit Fallback auf das Katalog-Icon.
class GameLogo extends StatelessWidget {
  const GameLogo({required this.game, this.size = 48, super.key});

  final GameDefinition game;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final asset = game.logoAsset;
    if (asset == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tokens.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(game.icon, color: tokens.primary, size: size / 2),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: game.name,
      ),
    );
  }
}
