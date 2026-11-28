import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/games/models/game_models.dart';
import 'package:sinclear_beyond/features/games/models/minecraft_overview.dart';

Map<String, dynamic> _overviewJson() {
  return <String, dynamic>{
    'scope': 'server',
    'serverId': 'MedionSMP',
    'rankedBy': <String, dynamic>{
      'category': 'minecraft:custom',
      'stat': 'minecraft:play_time',
    },
    'sources': <dynamic>[
      <String, dynamic>{
        'sourceId': 1,
        'serverId': 'MedionSMP',
        'world': 'world',
        'lastCollectedAt': '2026-11-28T11:55:00Z',
        'playerCount': 2,
        'totals': <String, dynamic>{
          'minecraft:custom': <String, dynamic>{'minecraft:play_time': 180},
        },
        'ranking': <dynamic>[],
      },
    ],
    'servers': <dynamic>[
      <String, dynamic>{
        'serverId': 'MedionSMP',
        'worlds': <String>['world', 'nether'],
        'lastCollectedAt': '2026-11-28T11:55:00Z',
        'playerCount': 2,
        'totals': <String, dynamic>{
          'minecraft:custom': <String, dynamic>{
            'minecraft:play_time': 180,
            'minecraft:deaths': 4,
            'minecraft:walk_one_cm': 50000,
          },
          'minecraft:mined': <String, dynamic>{
            'minecraft:stone': 40,
            'minecraft:dirt': 25,
          },
        },
        'ranking': <dynamic>[
          <String, dynamic>{
            'rank': 1,
            'uuid': 'f6d584ff-9577-472b-9aa2-88b7878eac37',
            'name': 'Notch',
            'linkedUserId': 'usr_123',
            'avatarUrl': 'https://mc-heads.net/avatar/f6d584ff/64',
            'value': 130,
          },
          <String, dynamic>{
            'rank': 2,
            'uuid': 'ca48cfb5-bfcb-4f25-bbbf-966cb5892c80',
            'name': null,
            'linkedUserId': null,
            'avatarUrl': null,
            'value': 50,
          },
        ],
      },
    ],
    'generatedAt': '2026-11-28T12:00:00Z',
  };
}

MinecraftStats _playerStats() {
  return const MinecraftStats(
    sources: <MinecraftStatsSource>[
      MinecraftStatsSource(
        serverId: 'survival-1',
        world: 'world',
        stats: <String, Map<String, int>>{
          'minecraft:custom': <String, int>{'minecraft:play_time': 24000},
        },
      ),
      MinecraftStatsSource(
        serverId: 'survival-1',
        world: 'nether',
        stats: <String, Map<String, int>>{
          'minecraft:custom': <String, int>{'minecraft:deaths': 2},
        },
      ),
      MinecraftStatsSource(
        serverId: 'creative',
        world: 'world',
        stats: <String, Map<String, int>>{
          'minecraft:custom': <String, int>{'minecraft:play_time': 6000},
        },
      ),
    ],
  );
}

void main() {
  group('MinecraftOverview', () {
    test('parst Server, Summen und Rangliste', () {
      final overview = MinecraftOverview.fromJson(_overviewJson());

      expect(overview.isGlobal, isFalse);
      expect(overview.serverId, 'MedionSMP');
      expect(overview.servers, hasLength(1));

      final server = overview.servers.single;
      expect(server.worlds, <String>['world', 'nether']);
      expect(server.playerCount, 2);
      expect(server.value('minecraft:custom', 'minecraft:play_time'), 180);
      expect(server.total('minecraft:mined'), 65);
      expect(server.distanceCm, 50000);
      expect(server.top('minecraft:mined').map((entry) => entry.stat), <String>[
        'minecraft:stone',
        'minecraft:dirt',
      ]);
      expect(server.ranking, hasLength(2));
      expect(server.ranking.first.displayName, 'Notch');
      expect(server.ranking.first.linkedUserId, 'usr_123');
      // Unverknüpfte Spieler erscheinen ebenfalls, nur ohne Namen/Avatar.
      expect(server.ranking.last.displayName, 'Unbekannt');
      expect(server.ranking.last.avatarUrl, isNull);
    });

    test('asStats bildet die Server-Summen als eine Quelle ab', () {
      final stats = MinecraftOverview.fromJson(
        _overviewJson(),
      ).servers.single.asStats();

      expect(stats.sources, hasLength(1));
      expect(stats.playTimeTicks, 180);
      expect(stats.deaths, 4);
      expect(stats.distanceCm, 50000);
      expect(stats.blocksMined, 65);
    });
  });

  group('MinecraftStats-Serverfilter', () {
    test('serverIds liefert die Server eindeutig und sortiert', () {
      expect(_playerStats().serverIds, <String>['creative', 'survival-1']);
    });

    test('forServer summiert nur die Quellen des Servers', () {
      final filtered = _playerStats().forServer('survival-1');

      expect(filtered.sources, hasLength(2));
      expect(filtered.playTimeTicks, 24000);
      expect(filtered.deaths, 2);
    });

    test('forServer mit null ändert nichts', () {
      final stats = _playerStats();
      expect(identical(stats.forServer(null), stats), isTrue);
    });

    test('forServer ohne Treffer liefert leere Quellen', () {
      final filtered = _playerStats().forServer('unbekannt');
      expect(filtered.sources, isEmpty);
      expect(filtered.playTimeTicks, 0);
    });
  });
}
