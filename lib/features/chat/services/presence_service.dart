import 'dart:async';

import 'package:logging/logging.dart';

import '../../auth/services/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../models/user_presence.dart';

final _log = Logger('chat.presence');

/// Service für Nutzer-Präsenz-Abfragen über die API.
///
/// Kombiniert Echtzeit-Präsenz (Centrifugo) mit `lastActiveAt` (UserActivity).
class PresenceService {
  PresenceService({required ApiClient api, required AuthService auth})
      : _api = api,
        _auth = auth;

  final ApiClient _api;
  final AuthService _auth;

  Future<String> _token() => _auth.getAccessToken();

  /// Cache für Presence-Abfragen (userId → UserPresence).
  final Map<String, UserPresence> _cache = {};

  /// Letzte Bulk-Abfrage (userIds → UserPresence).
  Map<String, UserPresence> _bulkCache = {};

  /// Zeitpunkt der letzten Bulk-Abfrage.
  DateTime? _lastBulkFetch;

  /// Cache-Timeout in Sekunden.
  static const int _cacheTimeoutSeconds = 30;

  /// Holt den Online-Status eines einzelnen Nutzers.
  ///
  /// Nutzt den Cache, wenn vorhanden und aktuell.
  Future<UserPresence?> getPresence(String userId) async {
    final cached = _cache[userId];
    if (cached != null && _isCacheValid()) {
      return cached;
    }

    try {
      final data = await _api.get(
        '/chat/presence/$userId',
        token: await _token(),
      );
      if (data['data'] != null) {
        final presence = UserPresence.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        _cache[userId] = presence;
        return presence;
      }
    } catch (e, st) {
      _log.warning('getPresence($userId) failed', e, st);
    }
    return null;
  }

  /// Holt den Online-Status mehrerer Nutzer auf einmal.
  ///
  /// Nutzt den Cache für bekannte User.
  Future<Map<String, UserPresence>> getBulkPresence(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    // Prüfe ob wir alle User im Cache haben
    final allCached = userIds.every(
      (id) => _cache.containsKey(id) && _isCacheValid(),
    );
    if (allCached) {
      return Map.fromEntries(
        userIds.map((id) => MapEntry(id, _cache[id]!)),
      );
    }

    try {
      // Build query string manually for array parameter
      final queryParams = <String, String>{};
      for (final id in userIds) {
        queryParams['userIds[]'] = id;
      }
      final data = await _api.get(
        '/chat/presence',
        token: await _token(),
        queryParams: queryParams,
      );
      if (data['data'] != null) {
        final entries = data['data'] as Map<String, dynamic>;
        final result = <String, UserPresence>{};
        for (final entry in entries.entries) {
          final presence = UserPresence.fromJson(
            entry.value as Map<String, dynamic>,
          );
          result[entry.key] = presence;
          _cache[entry.key] = presence;
        }
        _bulkCache = result;
        _lastBulkFetch = DateTime.now();
        return result;
      }
    } catch (e, st) {
      _log.warning('getBulkPresence() failed', e, st);
    }
    return {};
  }

  /// Aktualisiert den Cache mit Echtzeit-Daten von Centrifugo.
  void updateFromCentrifugo(String userId, bool online) {
    _cache[userId] = UserPresence(
      online: online,
      lastJoin: online ? DateTime.now().toUtc().toIso8601String() : null,
      lastLeave: !online ? DateTime.now().toUtc().toIso8601String() : null,
      lastSeen: !online ? DateTime.now().toUtc().toIso8601String() : null,
    );
  }

  /// Leert den Cache.
  void clearCache() {
    _cache.clear();
    _bulkCache.clear();
    _lastBulkFetch = null;
  }

  bool _isCacheValid() {
    final lastFetch = _lastBulkFetch;
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch).inSeconds <
        _cacheTimeoutSeconds;
  }
}
