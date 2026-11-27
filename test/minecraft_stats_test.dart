import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/features/games/models/game_models.dart';
import 'package:sinclear_beyond/features/games/utils/game_error_messages.dart';
import 'package:sinclear_beyond/features/games/utils/game_format.dart';

Map<String, dynamic> _sampleMinecraftStats() {
  return <String, dynamic>{
    'accountId': 'ca48cfb5-bfcb-4f25-bbbf-966cb5892c80',
    'player': <String, dynamic>{
      'uuid': 'ca48cfb5-bfcb-4f25-bbbf-966cb5892c80',
      'name': 'Notch',
    },
    'sources': <dynamic>[
      <String, dynamic>{
        'serverId': 'survival-1',
        'world': 'world',
        'collectedAt': '2026-11-27T21:00:00Z',
        'stats': <String, dynamic>{
          'minecraft:custom': <String, dynamic>{
            'minecraft:play_time': 24000,
            'minecraft:deaths': 2,
            'minecraft:mob_kills': 10,
            'minecraft:jump': 5,
            'minecraft:walk_one_cm': 50000,
          },
          'minecraft:mined': <String, dynamic>{
            'minecraft:stone': 100,
            'minecraft:dirt': 50,
          },
        },
      },
      <String, dynamic>{
        'serverId': 'survival-1',
        'world': 'nether',
        'collectedAt': '2026-11-27T20:00:00Z',
        'stats': <String, dynamic>{
          'minecraft:custom': <String, dynamic>{
            'minecraft:play_time': 12000,
            'minecraft:deaths': 1,
            'minecraft:mob_kills': 4,
            'minecraft:walk_one_cm': 25000,
          },
          'minecraft:mined': <String, dynamic>{'minecraft:netherrack': 25},
        },
      },
    ],
    'syncedAt': '2026-11-27T21:00:00Z',
  };
}

void main() {
  group('MinecraftStats', () {
    test('parst Quellen, Spieler und aggregiert Zähler', () {
      final stats = MinecraftStats.fromJson(_sampleMinecraftStats());

      expect(stats.playerName, 'Notch');
      expect(stats.sources, hasLength(2));
      expect(stats.playTimeTicks, 36000);
      expect(stats.deaths, 3);
      expect(stats.mobKills, 14);
      expect(stats.jumps, 5);
      expect(stats.blocksMined, 175);
      expect(stats.distanceCm, 75000);
      expect(stats.syncedAt, '2026-11-27T21:00:00Z');
    });

    test('top liefert die größten Zähler einer Kategorie', () {
      final stats = MinecraftStats.fromJson(_sampleMinecraftStats());
      final top = stats.top('minecraft:mined');

      expect(top.map((entry) => entry.stat), <String>[
        'minecraft:stone',
        'minecraft:dirt',
        'minecraft:netherrack',
      ]);
      expect(top.map((entry) => entry.value), <int>[100, 50, 25]);
    });

    test('allEntries summiert gleiche Zähler über Quellen', () {
      final stats = MinecraftStats.fromJson(_sampleMinecraftStats());
      final entries = stats.allEntries;

      expect(entries, hasLength(8));
      final playTime = entries.firstWhere(
        (entry) => entry.stat == 'minecraft:play_time',
      );
      expect(playTime.value, 36000);
    });

    test('GameStatsResponse erkennt Minecraft-Statistiken', () {
      final response = GameStatsResponse.fromJson(<String, dynamic>{
        'game': 'minecraft',
        'userId': 'u1',
        'accountId': 'ca48cfb5-bfcb-4f25-bbbf-966cb5892c80',
        'stats': _sampleMinecraftStats(),
        'lastRefreshedAt': '2026-11-27T21:00:00Z',
        'nextRefreshAt': null,
      });

      expect(response.hasStats, isTrue);
      expect(response.stats, isNull);
      expect(response.minecraft?.playerName, 'Notch');
    });

    test('GameStatsResponse lässt Minecraft bei Deadlock null', () {
      final response = GameStatsResponse.fromJson(<String, dynamic>{
        'game': 'deadlock',
        'userId': 'u1',
        'accountId': '42',
        'stats': null,
      });

      expect(response.hasStats, isFalse);
      expect(response.minecraft, isNull);
    });
  });

  group('Minecraft-Formatierung', () {
    test('Ticks werden als Dauer ausgegeben', () {
      expect(formatTicksAsDuration(36000), '30 Min.');
      expect(formatTicksAsDuration(72000), '1 Std. 0 Min.');
      expect(formatTicksAsDuration(0), '0 Min.');
    });

    test('Zentimeter werden als Distanz ausgegeben', () {
      expect(formatCentimeters(50), '50 cm');
      expect(formatCentimeters(75000), '750,0 m');
      expect(formatCentimeters(150000), '1,5 km');
    });

    test('Stat-Werte und Labels', () {
      expect(
        formatMinecraftStatValue(
          'minecraft:custom',
          'minecraft:play_time',
          36000,
        ),
        '30 Min.',
      );
      expect(minecraftStatLabel('minecraft:play_time'), 'Spielzeit');
      expect(minecraftStatLabel('minecraft:custom_thing'), 'Custom thing');
      expect(minecraftCategoryLabel('minecraft:mined'), 'Abgebaute Blöcke');
    });
  });

  group('Minecraft-Fehlertexte', () {
    test('nennt UUID/Username statt Steam-ID', () {
      expect(
        gameErrorMessage(
          const ApiException(errorCode: 'invalid_account_id', statusCode: 400),
          game: 'minecraft',
        ),
        contains('Minecraft-UUID'),
      );
      expect(
        gameErrorMessage(
          const ApiException(errorCode: 'account_not_found', statusCode: 400),
          game: 'minecraft',
        ),
        contains('Minecraft-Account'),
      );
    });

    test('meldet bereits verknüpfte Accounts', () {
      expect(
        gameErrorMessage(
          const ApiException(
            errorCode: 'account_already_linked',
            statusCode: 409,
          ),
        ),
        contains('bereits'),
      );
    });
  });
}
