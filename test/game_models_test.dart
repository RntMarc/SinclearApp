import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/games/models/game_models.dart';
import 'package:sinclear_beyond/features/games/utils/game_error_messages.dart';
import 'package:sinclear_beyond/features/games/utils/game_format.dart';
import 'package:sinclear_beyond/features/games/utils/steam_id.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';

Map<String, dynamic> _heroJson({
  int heroId = 2,
  String? heroName = 'Seven',
  int matches = 2,
  int wins = 1,
  int minutes = 60,
  double netWorthPerMin = 500,
}) {
  return <String, dynamic>{
    'heroId': heroId,
    'heroName': heroName,
    'heroIconUrl': 'https://example.test/hero.png',
    'matchesPlayed': matches,
    'wins': wins,
    'losses': matches - wins,
    'winRate': matches == 0 ? 0.0 : wins / matches,
    'lastPlayed': '2026-10-18T20:14:56Z',
    'timePlayedSeconds': minutes * 60,
    'endingLevel': 20.5,
    'kills': 10,
    'deaths': 5,
    'assists': 15,
    'killsPerMin': 0.5,
    'deathsPerMin': 0.25,
    'assistsPerMin': 0.75,
    'networthPerMin': netWorthPerMin,
    'lastHitsPerMin': 4.0,
    'deniesPerMin': 0.5,
    'damagePerMin': 600,
    'damageTakenPerMin': 700,
    'accuracy': 0.5,
  };
}

Map<String, dynamic> _matchJson({
  int outcome = 1,
  int matchResult = 0,
  int playerTeam = 0,
}) {
  return <String, dynamic>{
    'matchId': '123',
    'heroId': 87,
    'heroName': 'Nurse Harrow',
    'heroIconUrl': 'https://example.test/nurse.png',
    'heroLevel': 36,
    'startTime': '2026-10-24T20:02:14Z',
    'gameMode': 4,
    'matchMode': 1,
    'playerTeam': playerTeam,
    'kills': 7,
    'deaths': 4,
    'assists': 23,
    'netWorth': 58231,
    'lastHits': 185,
    'denies': 1,
    'matchDurationSeconds': 2852,
    'matchResult': matchResult,
    'playerMatchOutcome': outcome,
    'abandonedTimeSeconds': 0,
  };
}

void main() {
  group('Steam-ID', () {
    test('akzeptiert SteamID3 unverändert', () {
      expect(normalizeSteamId('179673173'), '179673173');
      expect(normalizeSteamId(' 179673173 '), '179673173');
    });

    test('rechnet SteamID64 in SteamID3 um', () {
      expect(normalizeSteamId('76561198139938901'), '179673173');
    });

    test('lehnt ungültige Eingaben ab', () {
      expect(normalizeSteamId(''), isNull);
      expect(normalizeSteamId('abc'), isNull);
      expect(normalizeSteamId('0'), isNull);
      expect(normalizeSteamId('4294967296'), isNull);
      expect(normalizeSteamId('76561197960265728'), isNull);
      expect(normalizeSteamId('99999999999999999999'), isNull);
    });
  });

  group('Rang', () {
    test('nutzt API-Namen und römische Subränge', () {
      const rank = DeadlockRank(tier: 10, subrank: 3, name: 'Ascendant');
      expect(rank.label, 'Ascendant III');
    });

    test('fällt auf lokale Tier-Namen zurück', () {
      expect(rankNameForTier(0), 'Obscurus');
      expect(rankNameForTier(1), 'Initiate');
      expect(rankNameForTier(11), 'Eternus');
      expect(rankNameForTier(99), 'Rang 99');
      expect(const DeadlockRank(tier: 0).label, 'Obscurus');
      expect(const DeadlockRank(tier: 6, subrank: 2).label, 'Ritualist II');
    });

    test('ohne Subrank bleibt nur der Tier-Name', () {
      expect(const DeadlockRank(tier: 4).label, 'Sentinel');
    });
  });

  group('JSON-Parsing', () {
    test('parst vollständige Deadlock-Statistiken', () {
      final stats = DeadlockStats.fromJson(<String, dynamic>{
        'accountId': '179673173',
        'rank': <String, dynamic>{
          'badge': 12,
          'rank': 1,
          'subrank': 2,
          'name': 'Initiate',
          'iconUrl': 'https://example.test/rank.png',
          'lastMatch': <String, dynamic>{
            'matchId': '999',
            'startTime': '2026-10-25T14:00:00Z',
          },
        },
        'heroStats': <dynamic>[_heroJson()],
        'matchHistory': <dynamic>[_matchJson()],
        'syncedAt': '2026-10-25T14:00:00Z',
      });

      expect(stats.rank?.label, 'Initiate II');
      expect(stats.rank?.lastMatchId, '999');
      expect(stats.heroStats.single.displayName, 'Seven');
      expect(stats.heroStats.single.kda, closeTo(5, 0.001));
      expect(stats.matchHistory.single.displayName, 'Nurse Harrow');
      expect(stats.matchHistory.single.outcome, MatchOutcome.win);
      expect(stats.matchHistory.single.gameModeLabel, 'Street Brawl');
    });

    test('fehlende Felder und leere Listen sind null-sicher', () {
      final stats = DeadlockStats.fromJson(<String, dynamic>{
        'accountId': '1',
        'rank': null,
        'heroStats': null,
        'matchHistory': <dynamic>[],
      });
      expect(stats.rank, isNull);
      expect(stats.heroStats, isEmpty);
      expect(stats.matchHistory, isEmpty);
      expect(stats.syncedAt, isNull);
    });

    test('Hero ohne Namen nutzt die Held-Nummer', () {
      final hero = DeadlockHeroStat.fromJson(
        _heroJson(heroId: 99, heroName: null),
      );
      expect(hero.displayName, 'Held #99');
    });

    test('GameStatsResponse erlaubt stats = null', () {
      final response = GameStatsResponse.fromJson(<String, dynamic>{
        'game': 'deadlock',
        'userId': 'u1',
        'accountId': '42',
        'stats': null,
        'lastRefreshedAt': null,
        'nextRefreshAt': null,
      });
      expect(response.stats, isNull);
      expect(response.accountId, '42');
    });
  });

  group('Match-Ergebnis', () {
    test('wertet playerMatchOutcome aus', () {
      expect(
        DeadlockMatch.fromJson(_matchJson(outcome: 1)).outcome,
        MatchOutcome.win,
      );
      expect(
        DeadlockMatch.fromJson(_matchJson(outcome: 2)).outcome,
        MatchOutcome.loss,
      );
      expect(
        DeadlockMatch.fromJson(_matchJson(outcome: 3)).outcome,
        MatchOutcome.penalized,
      );
      expect(
        DeadlockMatch.fromJson(_matchJson(outcome: 5)).outcome,
        MatchOutcome.notScored,
      );
    });

    test('leitet bei fehlendem Outcome aus Team/Sieger ab', () {
      expect(
        DeadlockMatch.fromJson(
          _matchJson(outcome: 0, matchResult: 1, playerTeam: 1),
        ).outcome,
        MatchOutcome.win,
      );
      expect(
        DeadlockMatch.fromJson(
          _matchJson(outcome: 0, matchResult: 1, playerTeam: 0),
        ).outcome,
        MatchOutcome.loss,
      );
    });
  });

  group('Aggregate', () {
    test('berechnet Winrate, KDA und gewichtete Per-Min-Werte', () {
      final summary = GameSummary.fromStats(
        DeadlockStats.fromJson(<String, dynamic>{
          'heroStats': <dynamic>[
            _heroJson(matches: 3, wins: 2, minutes: 60, netWorthPerMin: 400),
            _heroJson(
              heroId: 7,
              heroName: 'Wraith',
              matches: 1,
              wins: 0,
              minutes: 30,
              netWorthPerMin: 1000,
            ),
          ],
          'matchHistory': <dynamic>[
            _matchJson(outcome: 1),
            _matchJson(outcome: 2),
            _matchJson(outcome: 3),
          ],
        }),
      );

      expect(summary.matches, 4);
      expect(summary.wins, 2);
      expect(summary.losses, 2);
      expect(summary.winRate, closeTo(0.5, 0.0001));
      expect(summary.kda, closeTo(5, 0.0001));
      // 60 Min. à 400 + 30 Min. à 1000 = 54000 / 90 = 600
      expect(summary.netWorthPerMin, closeTo(600, 0.0001));
      expect(summary.heroes.first.displayName, 'Seven');
      expect(summary.recentWins, 1);
      expect(summary.recentLosses, 1);
      expect(summary.topHero?.displayName, 'Seven');
      expect(summary.recentMatches, hasLength(3));
    });

    test('sortiert Top-Helden nach gespielter Zeit statt nach Matches', () {
      final summary = GameSummary.fromStats(
        DeadlockStats.fromJson(<String, dynamic>{
          'heroStats': <dynamic>[
            _heroJson(matches: 10, wins: 5, minutes: 30),
            _heroJson(
              heroId: 7,
              heroName: 'Wraith',
              matches: 2,
              wins: 2,
              minutes: 300,
            ),
          ],
        }),
      );

      expect(summary.heroes.first.displayName, 'Wraith');
      expect(summary.topHero?.displayName, 'Wraith');
    });

    test('leere Statistiken ergeben einen leeren Summary', () {
      final summary = GameSummary.fromStats(const DeadlockStats());
      expect(summary.matches, 0);
      expect(summary.winRate, 0);
      expect(summary.kda, 0);
      expect(summary.heroes, isEmpty);
      expect(summary.topHero, isNull);
    });
  });

  group('Formatierung', () {
    test('Prozent, Dezimal und Dauer', () {
      expect(formatPercent(0.5), '50 %');
      expect(formatDecimal(3.456, digits: 2), '3,46');
      expect(formatInt(12345), '12.345');
      expect(formatMatchDuration(2852), '47:32');
      expect(formatMatchDuration(0), '–');
      expect(formatPlayedMinutes(3118), '51 Min.');
    });
  });

  group('Fehlertexte', () {
    test('übersetzt Spiele-Fehlercodes', () {
      expect(
        gameErrorMessage(
          const ApiException(errorCode: 'account_not_found', statusCode: 400),
        ),
        contains('kein Profil'),
      );
      expect(
        gameErrorMessage(
          const ApiException(
            errorCode: 'game_api_unavailable',
            statusCode: 503,
          ),
        ),
        contains('nicht erreichbar'),
      );
      expect(
        gameErrorMessage(
          const ApiException(errorCode: 'invalid_account_id', statusCode: 400),
        ),
        contains('Steam-ID'),
      );
      expect(
        gameErrorMessage(const ApiException(errorCode: 'x', statusCode: 500)),
        contains('fehlgeschlagen'),
      );
      expect(gameErrorMessage(StateError('boom')), contains('fehlgeschlagen'));
    });
  });
}
