import 'package:flutter/material.dart';

/// Ein im Client unterstütztes Spiel.
///
/// Die API hat (noch) keinen Endpoint, der die registrierten Spiele auflistet.
/// Deshalb pflegt der Client den Katalog lokal; ein neues Spiel braucht hier
/// einen Eintrag und eine passende Statistik-Darstellung.
class GameDefinition {
  const GameDefinition({
    required this.slug,
    required this.name,
    required this.icon,
    this.logoAsset,
  });

  final String slug;
  final String name;

  /// Fallback-Icon, wenn kein [logoAsset] hinterlegt ist.
  final IconData icon;

  /// Pfad zum Spiel-Logo im Asset-Bundle (optional).
  final String? logoAsset;
}

const List<GameDefinition> gameCatalog = <GameDefinition>[
  GameDefinition(
    slug: 'deadlock',
    name: 'Deadlock',
    icon: Icons.sports_esports_rounded,
    logoAsset: 'assets/games/deadlock.png',
  ),
];

/// Liefert die Definition zu einem Spiel-Slug, falls unterstützt.
GameDefinition? gameForSlug(String slug) {
  for (final game in gameCatalog) {
    if (game.slug == slug) return game;
  }
  return null;
}
