// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/game_models.dart';

/// Zugriff auf verknüpfte Spiele-Accounts und Spielstatistiken.
class GamesService {
  GamesService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  final ApiClient _api;
  final AuthService _auth;

  /// Die API akzeptiert höchstens 100 Nutzer-IDs pro Batch-Abfrage.
  static const int maxBatchUsers = 100;

  Future<String> _token() => _auth.getAccessToken();

  /// Eigene verknüpfte Accounts.
  Future<List<GameAccount>> listMine() async {
    final data = await _api.get('/user/me/games', token: await _token());
    return _parseAccounts(data);
  }

  /// Verknüpft (oder ersetzt) den Account für ein Spiel.
  Future<GameAccount> link(String game, String accountId) async {
    final data = await _api.put(
      '/user/me/games/$game',
      body: <String, dynamic>{'accountId': accountId},
      token: await _token(),
    );
    return GameAccount.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Löst die Verknüpfung eines Spiels.
  Future<void> unlink(String game) async {
    await _api.delete('/user/me/games/$game', token: await _token());
  }

  /// Öffentliche Liste der verknüpften Accounts eines anderen Nutzers.
  Future<List<GameAccount>> listForUser(String userId) async {
    final data = await _api.get('/user/$userId/games', token: await _token());
    return _parseAccounts(data);
  }

  /// Statistiken eines einzelnen Nutzers.
  Future<GameStatsResponse> stats(String game, String userId) async {
    final data = await _api.get(
      '/games/$game/stats/$userId',
      token: await _token(),
    );
    return GameStatsResponse.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Batch-Statistiken (max. 100 IDs pro Aufruf, wird automatisch gechunkt).
  Future<List<GameStatsResponse>> batchStats(
    String game,
    List<String> userIds,
  ) async {
    final unique = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final result = <GameStatsResponse>[];
    for (var start = 0; start < unique.length; start += maxBatchUsers) {
      final end = (start + maxBatchUsers).clamp(0, unique.length);
      final chunk = unique.sublist(start, end);
      final data = await _api.get(
        '/games/$game/stats',
        queryParams: <String, String>{'userIds': chunk.join(',')},
        token: await _token(),
      );
      final list = data['data'];
      if (list is List) {
        result.addAll(
          list.whereType<Map<String, dynamic>>().map(
            GameStatsResponse.fromJson,
          ),
        );
      }
    }
    return result;
  }

  List<GameAccount> _parseAccounts(Map<String, dynamic> data) {
    final list = data['data'];
    if (list is! List) return const <GameAccount>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(GameAccount.fromJson)
        .toList();
  }
}
