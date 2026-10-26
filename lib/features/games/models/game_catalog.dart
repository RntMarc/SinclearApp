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
  });

  final String slug;
  final String name;
  final IconData icon;
}

const List<GameDefinition> gameCatalog = <GameDefinition>[
  GameDefinition(
    slug: 'deadlock',
    name: 'Deadlock',
    icon: Icons.sports_esports_rounded,
  ),
];

/// Liefert die Definition zu einem Spiel-Slug, falls unterstützt.
GameDefinition? gameForSlug(String slug) {
  for (final game in gameCatalog) {
    if (game.slug == slug) return game;
  }
  return null;
}
