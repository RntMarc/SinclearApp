/// Die Score-Richtung eines Arcade-Spiels.
enum ScoreDirection {
  /// Kleinere Werte sind besser (z. B. Zeitrennen).
  asc,

  /// Größere Werte sind besser (z. B. Punkte).
  desc,
}

/// Ein aktives, selbst gehostetes Arcade-Browser-Spiel aus dem Katalog
/// (`GET /arcade/games`).
class ArcadeGame {
  const ArcadeGame({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.scoreDirection,
    required this.playUrl,
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final ScoreDirection scoreDirection;

  /// Basis-Play-URL ohne Session-Token.
  final String playUrl;

  factory ArcadeGame.fromJson(Map<String, dynamic> json) {
    return ArcadeGame(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      scoreDirection: json['scoreDirection'] == 'asc'
          ? ScoreDirection.asc
          : ScoreDirection.desc,
      playUrl: json['playUrl'] as String? ?? '',
    );
  }
}

/// Eine ausgestellte Arcade-Session (`POST /arcade/games/{slug}/session`).
///
/// [playUrl] enthält das kurzlebige [token] bereits im URL-Fragment
/// (`#arcade_token=…`); das Spiel liest es dort aus.
class ArcadeSession {
  const ArcadeSession({
    required this.token,
    required this.playUrl,
    this.expiresAt,
  });

  final String token;
  final String playUrl;
  final String? expiresAt;

  factory ArcadeSession.fromJson(Map<String, dynamic> json) {
    return ArcadeSession(
      token: json['token'] as String? ?? '',
      playUrl: json['playUrl'] as String? ?? '',
      expiresAt: json['expiresAt'] as String?,
    );
  }
}
