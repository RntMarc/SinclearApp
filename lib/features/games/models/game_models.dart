import 'dart:math' as math;

/// Ein mit dem Beyond-Konto verknüpfter Spiele-Account.
///
/// Die API speichert nur Profil-/Identitätsdaten; die Statistiken kommen aus
/// dem Cache über [GameStatsResponse].
class GameAccount {
  const GameAccount({
    required this.id,
    required this.userId,
    required this.game,
    required this.accountId,
    this.displayName,
    this.avatarUrl,
    this.lastSyncedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String game;
  final String accountId;
  final String? displayName;
  final String? avatarUrl;
  final String? lastSyncedAt;
  final String? createdAt;
  final String? updatedAt;

  factory GameAccount.fromJson(Map<String, dynamic> json) {
    return GameAccount(
      id: json['id'] as String,
      userId: json['userId'] as String,
      game: json['game'] as String,
      accountId: json['accountId'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      lastSyncedAt: json['lastSyncedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

/// Statistik-Antwort für einen Beyond-Nutzer.
///
/// [stats] ist `null`, solange der Cronjob den Cache noch nicht gefüllt hat.
class GameStatsResponse {
  const GameStatsResponse({
    required this.game,
    required this.userId,
    required this.accountId,
    this.stats,
    this.lastRefreshedAt,
    this.nextRefreshAt,
  });

  final String game;
  final String userId;
  final String accountId;
  final DeadlockStats? stats;
  final String? lastRefreshedAt;
  final String? nextRefreshAt;

  factory GameStatsResponse.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'];
    return GameStatsResponse(
      game: json['game'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      stats: rawStats is Map<String, dynamic>
          ? DeadlockStats.fromJson(rawStats)
          : null,
      lastRefreshedAt: json['lastRefreshedAt'] as String?,
      nextRefreshAt: json['nextRefreshAt'] as String?,
    );
  }
}

/// Normalisierte Deadlock-Statistiken aus dem API-Cache.
class DeadlockStats {
  const DeadlockStats({
    this.accountId,
    this.rank,
    this.heroStats = const <DeadlockHeroStat>[],
    this.matchHistory = const <DeadlockMatch>[],
    this.syncedAt,
  });

  final String? accountId;
  final DeadlockRank? rank;
  final List<DeadlockHeroStat> heroStats;
  final List<DeadlockMatch> matchHistory;
  final String? syncedAt;

  factory DeadlockStats.fromJson(Map<String, dynamic> json) {
    final rawRank = json['rank'];
    final rawHeroes = json['heroStats'];
    final rawMatches = json['matchHistory'];
    return DeadlockStats(
      accountId: json['accountId']?.toString(),
      rank: rawRank is Map<String, dynamic>
          ? DeadlockRank.fromJson(rawRank)
          : null,
      heroStats: rawHeroes is List
          ? rawHeroes
                .whereType<Map<String, dynamic>>()
                .map(DeadlockHeroStat.fromJson)
                .toList()
          : const <DeadlockHeroStat>[],
      matchHistory: rawMatches is List
          ? rawMatches
                .whereType<Map<String, dynamic>>()
                .map(DeadlockMatch.fromJson)
                .toList()
          : const <DeadlockMatch>[],
      syncedAt: json['syncedAt'] as String?,
    );
  }
}

/// Rang eines Deadlock-Spielers (Tier + Subrank).
class DeadlockRank {
  const DeadlockRank({
    this.badge = 0,
    this.tier = 0,
    this.subrank = 0,
    this.name,
    this.iconUrl,
    this.lastMatchId,
    this.lastMatchStartAt,
  });

  final int badge;
  final int tier;
  final int subrank;
  final String? name;
  final String? iconUrl;
  final String? lastMatchId;
  final String? lastMatchStartAt;

  factory DeadlockRank.fromJson(Map<String, dynamic> json) {
    final lastMatch = json['lastMatch'];
    return DeadlockRank(
      badge: (json['badge'] as num?)?.toInt() ?? 0,
      tier: (json['rank'] as num?)?.toInt() ?? 0,
      subrank: (json['subrank'] as num?)?.toInt() ?? 0,
      name: json['name'] as String?,
      iconUrl: json['iconUrl'] as String?,
      lastMatchId: lastMatch is Map<String, dynamic>
          ? lastMatch['matchId']?.toString()
          : null,
      lastMatchStartAt: lastMatch is Map<String, dynamic>
          ? lastMatch['startTime'] as String?
          : null,
    );
  }

  /// Anzeigename inkl. Subrank, z. B. „Ascendant III“.
  String get label {
    final tierName = (name == null || name!.isEmpty)
        ? rankNameForTier(tier)
        : name!;
    if (tier <= 0) return tierName;
    final roman = romanNumeral(subrank);
    return roman == null ? tierName : '$tierName $roman';
  }
}

/// Fallback-Namen der Deadlock-Rang-Tiers, falls die API keine Asset-Namen
/// liefert (z. B. wenn der Asset-Abruf beim Cron fehlschlug).
const List<String> _rankTiers = <String>[
  'Obscurus',
  'Initiate',
  'Seeker',
  'Acolyte',
  'Sentinel',
  'Mystic',
  'Ritualist',
  'Emissary',
  'Oracle',
  'Phantom',
  'Ascendant',
  'Eternus',
];

/// Liefert den Rangnamen für ein Tier (0 = unkalibriert).
String rankNameForTier(int tier) {
  if (tier < 0 || tier >= _rankTiers.length) return 'Rang $tier';
  return _rankTiers[tier];
}

/// Römische Ziffer für Subränge 1–6, sonst `null`.
String? romanNumeral(int value) => switch (value) {
  1 => 'I',
  2 => 'II',
  3 => 'III',
  4 => 'IV',
  5 => 'V',
  6 => 'VI',
  _ => null,
};

/// Helden-Statistik eines Accounts.
class DeadlockHeroStat {
  const DeadlockHeroStat({
    required this.heroId,
    this.heroName,
    this.heroIconUrl,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.winRate = 0,
    this.lastPlayed,
    this.timePlayedSeconds = 0,
    this.endingLevel,
    this.kills = 0,
    this.deaths = 0,
    this.assists = 0,
    this.killsPerMin,
    this.deathsPerMin,
    this.assistsPerMin,
    this.networthPerMin,
    this.lastHitsPerMin,
    this.deniesPerMin,
    this.damagePerMin,
    this.damageTakenPerMin,
    this.accuracy,
  });

  final int heroId;
  final String? heroName;
  final String? heroIconUrl;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final double winRate;
  final String? lastPlayed;
  final int timePlayedSeconds;
  final double? endingLevel;
  final int kills;
  final int deaths;
  final int assists;
  final double? killsPerMin;
  final double? deathsPerMin;
  final double? assistsPerMin;
  final double? networthPerMin;
  final double? lastHitsPerMin;
  final double? deniesPerMin;
  final double? damagePerMin;
  final double? damageTakenPerMin;
  final double? accuracy;

  factory DeadlockHeroStat.fromJson(Map<String, dynamic> json) {
    return DeadlockHeroStat(
      heroId: (json['heroId'] as num?)?.toInt() ?? 0,
      heroName: json['heroName'] as String?,
      heroIconUrl: json['heroIconUrl'] as String?,
      matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0,
      lastPlayed: json['lastPlayed'] as String?,
      timePlayedSeconds: (json['timePlayedSeconds'] as num?)?.toInt() ?? 0,
      endingLevel: (json['endingLevel'] as num?)?.toDouble(),
      kills: (json['kills'] as num?)?.toInt() ?? 0,
      deaths: (json['deaths'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      killsPerMin: (json['killsPerMin'] as num?)?.toDouble(),
      deathsPerMin: (json['deathsPerMin'] as num?)?.toDouble(),
      assistsPerMin: (json['assistsPerMin'] as num?)?.toDouble(),
      networthPerMin: (json['networthPerMin'] as num?)?.toDouble(),
      lastHitsPerMin: (json['lastHitsPerMin'] as num?)?.toDouble(),
      deniesPerMin: (json['deniesPerMin'] as num?)?.toDouble(),
      damagePerMin: (json['damagePerMin'] as num?)?.toDouble(),
      damageTakenPerMin: (json['damageTakenPerMin'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );
  }

  String get displayName =>
      (heroName == null || heroName!.isEmpty) ? 'Held #$heroId' : heroName!;

  double get kda => (kills + assists) / math.max(1, deaths);

  double get minutes => timePlayedSeconds / 60;
}

/// Ergebnis eines Matches aus Sicht des Spielers.
enum MatchOutcome { win, loss, penalized, notScored, unknown }

/// Ein Match aus der Match-History (max. 20, neueste zuerst).
class DeadlockMatch {
  const DeadlockMatch({
    this.matchId,
    required this.heroId,
    this.heroName,
    this.heroIconUrl,
    this.heroLevel = 0,
    this.startTime,
    this.gameMode = 0,
    this.matchMode = 0,
    this.playerTeam = 0,
    this.kills = 0,
    this.deaths = 0,
    this.assists = 0,
    this.netWorth = 0,
    this.lastHits = 0,
    this.denies = 0,
    this.matchDurationSeconds = 0,
    this.matchResult = 0,
    this.playerMatchOutcome = 0,
    this.abandonedTimeSeconds = 0,
  });

  final String? matchId;
  final int heroId;
  final String? heroName;
  final String? heroIconUrl;
  final int heroLevel;
  final String? startTime;
  final int gameMode;
  final int matchMode;
  final int playerTeam;
  final int kills;
  final int deaths;
  final int assists;
  final int netWorth;
  final int lastHits;
  final int denies;
  final int matchDurationSeconds;
  final int matchResult;
  final int playerMatchOutcome;
  final int abandonedTimeSeconds;

  factory DeadlockMatch.fromJson(Map<String, dynamic> json) {
    return DeadlockMatch(
      matchId: json['matchId']?.toString(),
      heroId: (json['heroId'] as num?)?.toInt() ?? 0,
      heroName: json['heroName'] as String?,
      heroIconUrl: json['heroIconUrl'] as String?,
      heroLevel: (json['heroLevel'] as num?)?.toInt() ?? 0,
      startTime: json['startTime'] as String?,
      gameMode: (json['gameMode'] as num?)?.toInt() ?? 0,
      matchMode: (json['matchMode'] as num?)?.toInt() ?? 0,
      playerTeam: (json['playerTeam'] as num?)?.toInt() ?? 0,
      kills: (json['kills'] as num?)?.toInt() ?? 0,
      deaths: (json['deaths'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      netWorth: (json['netWorth'] as num?)?.toInt() ?? 0,
      lastHits: (json['lastHits'] as num?)?.toInt() ?? 0,
      denies: (json['denies'] as num?)?.toInt() ?? 0,
      matchDurationSeconds:
          (json['matchDurationSeconds'] as num?)?.toInt() ?? 0,
      matchResult: (json['matchResult'] as num?)?.toInt() ?? 0,
      playerMatchOutcome: (json['playerMatchOutcome'] as num?)?.toInt() ?? 0,
      abandonedTimeSeconds:
          (json['abandonedTimeSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  MatchOutcome get outcome {
    switch (playerMatchOutcome) {
      case 1:
        return MatchOutcome.win;
      case 2:
        return MatchOutcome.loss;
      case 3:
      case 4:
        return MatchOutcome.penalized;
      case 5:
        return MatchOutcome.notScored;
    }
    // Ältere Einträge ohne Outcome: Sieger-Team steht in matchResult.
    if (matchResult == 0 || matchResult == 1) {
      return matchResult == playerTeam ? MatchOutcome.win : MatchOutcome.loss;
    }
    return MatchOutcome.unknown;
  }

  String get displayName =>
      (heroName == null || heroName!.isEmpty) ? 'Held #$heroId' : heroName!;

  double get kda => (kills + assists) / math.max(1, deaths);

  double get netWorthPerMin {
    if (matchDurationSeconds <= 0) return 0;
    return netWorth / (matchDurationSeconds / 60);
  }

  String? get gameModeLabel => switch (gameMode) {
    1 => 'Normal',
    4 => 'Street Brawl',
    _ => null,
  };
}

/// Aggregierte Kennzahlen eines Accounts, aus den Helden-Statistiken berechnet.
class GameSummary {
  const GameSummary({
    required this.matches,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.kda,
    required this.netWorthPerMin,
    required this.damagePerMin,
    required this.accuracy,
    required this.heroes,
    required this.recentMatches,
  });

  final int matches;
  final int wins;
  final int losses;
  final double winRate;
  final double kda;
  final double netWorthPerMin;
  final double damagePerMin;
  final double accuracy;
  final List<DeadlockHeroStat> heroes;
  final List<DeadlockMatch> recentMatches;

  static const GameSummary empty = GameSummary(
    matches: 0,
    wins: 0,
    losses: 0,
    winRate: 0,
    kda: 0,
    netWorthPerMin: 0,
    damagePerMin: 0,
    accuracy: 0,
    heroes: <DeadlockHeroStat>[],
    recentMatches: <DeadlockMatch>[],
  );

  factory GameSummary.fromStats(DeadlockStats stats) {
    var matches = 0;
    var wins = 0;
    var losses = 0;
    var kills = 0;
    var deaths = 0;
    var assists = 0;
    var minutes = 0.0;
    final weightedMinutes = <String, double>{};

    for (final hero in stats.heroStats) {
      matches += hero.matchesPlayed;
      wins += hero.wins;
      losses += hero.losses;
      kills += hero.kills;
      deaths += hero.deaths;
      assists += hero.assists;
      minutes += hero.minutes;
      _addWeight(weightedMinutes, 'kills', hero.killsPerMin, hero.minutes);
      _addWeight(weightedMinutes, 'deaths', hero.deathsPerMin, hero.minutes);
      _addWeight(weightedMinutes, 'assists', hero.assistsPerMin, hero.minutes);
      _addWeight(
        weightedMinutes,
        'netWorth',
        hero.networthPerMin,
        hero.minutes,
      );
      _addWeight(weightedMinutes, 'damage', hero.damagePerMin, hero.minutes);
      _addWeight(weightedMinutes, 'accuracy', hero.accuracy, hero.minutes);
    }

    final heroes =
        stats.heroStats.where((hero) => hero.matchesPlayed > 0).toList()
          ..sort(_compareHeroesByTime);

    return GameSummary(
      matches: matches,
      wins: wins,
      losses: losses,
      winRate: matches > 0 ? wins / matches : 0,
      kda: (kills + assists) / math.max(1, deaths),
      netWorthPerMin: _average(weightedMinutes, 'netWorth', minutes),
      damagePerMin: _average(weightedMinutes, 'damage', minutes),
      accuracy: _average(weightedMinutes, 'accuracy', minutes),
      heroes: heroes,
      recentMatches: stats.matchHistory,
    );
  }

  int get recentWins =>
      recentMatches.where((match) => match.outcome == MatchOutcome.win).length;

  int get recentLosses =>
      recentMatches.where((match) => match.outcome == MatchOutcome.loss).length;

  DeadlockHeroStat? get topHero => heroes.isEmpty ? null : heroes.first;

  /// Meistgespielte Helden zuerst; bei Gleichstand entscheiden die Matches.
  static int _compareHeroesByTime(DeadlockHeroStat a, DeadlockHeroStat b) {
    final byTime = b.timePlayedSeconds.compareTo(a.timePlayedSeconds);
    if (byTime != 0) return byTime;
    return b.matchesPlayed.compareTo(a.matchesPlayed);
  }

  static void _addWeight(
    Map<String, double> weights,
    String key,
    double? value,
    double weight,
  ) {
    if (value == null || weight <= 0) return;
    weights['$key.sum'] = (weights['$key.sum'] ?? 0) + value * weight;
    weights['$key.weight'] = (weights['$key.weight'] ?? 0) + weight;
  }

  static double _average(
    Map<String, double> weights,
    String key,
    double fallbackWeight,
  ) {
    final weight = weights['$key.weight'] ?? fallbackWeight;
    if (weight <= 0) return 0;
    return (weights['$key.sum'] ?? 0) / weight;
  }
}

/// Beyond-Nutzer mit verknüpftem Spiele-Account (für Picker/Vergleich).
class GamePlayer {
  const GamePlayer({
    required this.userId,
    required this.displayName,
    this.imageUrl,
    this.stats,
  });

  final String userId;
  final String displayName;
  final String? imageUrl;
  final GameStatsResponse? stats;

  DeadlockRank? get rank => stats?.stats?.rank;

  GameSummary get summary => stats?.stats == null
      ? GameSummary.empty
      : GameSummary.fromStats(stats!.stats!);
}
