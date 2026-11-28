import 'game_models.dart';

/// Aggregierte Server-Übersicht aus `GET /minecraft/sources`.
///
/// Die API summiert alle aktuellen Zähler über sämtliche getrackten Spieler –
/// unabhängig davon, ob ein Beyond-Profil verknüpft ist. `servers` ist bei
/// `scope == 'server'` auf genau einen Server gefiltert.
class MinecraftOverview {
  const MinecraftOverview({
    this.scope = 'global',
    this.serverId,
    this.servers = const <MinecraftServerOverview>[],
    this.generatedAt,
  });

  final String scope;
  final String? serverId;
  final List<MinecraftServerOverview> servers;
  final String? generatedAt;

  bool get isGlobal => scope != 'server';

  factory MinecraftOverview.fromJson(Map<String, dynamic> json) {
    final rawServers = json['servers'];
    return MinecraftOverview(
      scope: json['scope'] as String? ?? 'global',
      serverId: json['serverId'] as String?,
      servers: rawServers is List
          ? rawServers
                .whereType<Map<String, dynamic>>()
                .map(MinecraftServerOverview.fromJson)
                .toList()
          : const <MinecraftServerOverview>[],
      generatedAt: json['generatedAt'] as String?,
    );
  }
}

/// Ein Server mit den über alle Spieler summierten Vanilla-Zählern.
class MinecraftServerOverview {
  const MinecraftServerOverview({
    required this.serverId,
    this.worlds = const <String>[],
    this.lastCollectedAt,
    this.playerCount = 0,
    this.totals = const <String, Map<String, int>>{},
    this.ranking = const <MinecraftRankingEntry>[],
  });

  final String serverId;
  final List<String> worlds;
  final String? lastCollectedAt;

  /// Anzahl der Spieler mit mindestens einem Zähler auf diesem Server.
  final int playerCount;

  /// `{ "minecraft:custom": { "minecraft:play_time": 150 } }`
  final Map<String, Map<String, int>> totals;

  /// Von der API vorsortierte Rangliste (Default nach Spielzeit).
  final List<MinecraftRankingEntry> ranking;

  factory MinecraftServerOverview.fromJson(Map<String, dynamic> json) {
    final rawWorlds = json['worlds'];
    final rawRanking = json['ranking'];
    return MinecraftServerOverview(
      serverId: json['serverId'] as String? ?? '',
      worlds: rawWorlds is List
          ? rawWorlds.whereType<String>().toList()
          : const <String>[],
      lastCollectedAt: json['lastCollectedAt'] as String?,
      playerCount: (json['playerCount'] as num?)?.toInt() ?? 0,
      totals: parseMinecraftStats(json['totals']),
      ranking: rawRanking is List
          ? rawRanking
                .whereType<Map<String, dynamic>>()
                .map(MinecraftRankingEntry.fromJson)
                .toList()
          : const <MinecraftRankingEntry>[],
    );
  }

  /// Wert eines Zählers, über alle Welten summiert.
  int value(String category, String stat) => totals[category]?[stat] ?? 0;

  /// Summe aller Zähler einer Kategorie.
  int total(String category) {
    final values = totals[category];
    if (values == null) return 0;
    return values.values.fold(0, (sum, value) => sum + value);
  }

  /// Summe aller Distanz-Zähler (`*_one_cm`).
  int get distanceCm {
    var sum = 0;
    for (final category in totals.values) {
      for (final entry in category.entries) {
        if (entry.key.endsWith('_one_cm')) sum += entry.value;
      }
    }
    return sum;
  }

  /// Aggregierte Zähler einer Kategorie, absteigend nach Wert.
  List<MinecraftStatEntry> top(String category, {int limit = 5}) {
    final values = totals[category];
    if (values == null) return const <MinecraftStatEntry>[];
    final entries = <MinecraftStatEntry>[
      for (final entry in values.entries)
        MinecraftStatEntry(
          category: category,
          stat: entry.key,
          value: entry.value,
        ),
    ]..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Fasst die Server-Summen als [MinecraftStats] mit einer Quelle zusammen,
  /// damit die Übersicht dieselben Widgets wie die Spieler-Sicht nutzt.
  MinecraftStats asStats() {
    return MinecraftStats(
      sources: <MinecraftStatsSource>[
        MinecraftStatsSource(
          serverId: serverId,
          world: worlds.join(', '),
          collectedAt: lastCollectedAt,
          stats: totals,
        ),
      ],
      syncedAt: lastCollectedAt,
    );
  }
}

/// Ein Spieler in der Server-Rangliste.
class MinecraftRankingEntry {
  const MinecraftRankingEntry({
    required this.rank,
    required this.uuid,
    this.name,
    this.linkedUserId,
    this.avatarUrl,
    this.value = 0,
  });

  final int rank;
  final String uuid;
  final String? name;

  /// Beyond-Nutzer-ID, sofern die UUID verknüpft ist.
  final String? linkedUserId;
  final String? avatarUrl;

  /// Wert des Sortier-Zählers (Default: Spielzeit in Ticks).
  final int value;

  factory MinecraftRankingEntry.fromJson(Map<String, dynamic> json) {
    return MinecraftRankingEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String?,
      linkedUserId: json['linkedUserId'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      value: (json['value'] as num?)?.toInt() ?? 0,
    );
  }

  String get displayName {
    final trimmed = name?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Unbekannt' : trimmed;
  }
}
