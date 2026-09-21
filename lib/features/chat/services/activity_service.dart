import 'dart:async';

import 'package:logging/logging.dart';

import '../../auth/services/auth_service.dart';
import '../../../core/network/api_client.dart';

final _log = Logger('chat.activity');

/// Letzte Aktivität eines Nutzers.
class UserActivity {
  final String? lastActiveAt;
  final String? lastActiveEndpoint;

  const UserActivity({this.lastActiveAt, this.lastActiveEndpoint});

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      lastActiveAt: json['lastActiveAt'] as String?,
      lastActiveEndpoint: json['lastActiveEndpoint'] as String?,
    );
  }
}

/// Service für Nutzer-Aktivitäts-Abfragen über die API.
///
/// Dient als Fallback für Presence-Abfragen wenn Centrifugo offline ist.
class ActivityService {
  ActivityService({required ApiClient api, required AuthService auth})
      : _api = api,
        _auth = auth;

  final ApiClient _api;
  final AuthService _auth;

  Future<String> _token() => _auth.getAccessToken();

  /// Cache für Aktivitäts-Abfragen (userId → UserActivity).
  final Map<String, UserActivity> _cache = {};

  /// Cache-Timeout in Sekunden.
  static const int _cacheTimeoutSeconds = 60;

  /// Zeitpunkt der letzten Aktualisierung je User.
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Holt die letzte Aktivität eines einzelnen Nutzers.
  ///
  /// Nutzt den Cache, wenn vorhanden und aktuell.
  Future<UserActivity?> getLastActivity(String userId) async {
    final cached = _cache[userId];
    final cachedAt = _cacheTimestamps[userId];
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt).inSeconds < _cacheTimeoutSeconds) {
      return cached;
    }

    try {
      final data = await _api.get(
        '/users/activity',
        token: await _token(),
        queryParams: {'ids[]': userId},
      );
      if (data['data'] != null && data['data'][userId] != null) {
        final activity = UserActivity.fromJson(
          data['data'][userId] as Map<String, dynamic>,
        );
        _cache[userId] = activity;
        _cacheTimestamps[userId] = DateTime.now();
        return activity;
      }
    } catch (e, st) {
      _log.warning('getLastActivity($userId) failed', e, st);
    }
    return null;
  }

  /// Holt die letzte Aktivität mehrerer Nutzer auf einmal.
  ///
  /// Nutzt den Cache für bekannte User.
  Future<Map<String, UserActivity>> getBulkLastActivity(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    // Prüfe ob wir alle User im Cache haben und dieser aktuell ist
    final now = DateTime.now();
    final allCached = userIds.every((id) {
      final cachedAt = _cacheTimestamps[id];
      return cachedAt != null &&
          now.difference(cachedAt).inSeconds < _cacheTimeoutSeconds;
    });
    if (allCached) {
      return Map.fromEntries(
        userIds.map((id) => MapEntry(id, _cache[id]!)),
      );
    }

    try {
      final queryParams = <String, String>{};
      for (final id in userIds) {
        queryParams['ids[]'] = id;
      }
      final data = await _api.get(
        '/users/activity',
        token: await _token(),
        queryParams: queryParams,
      );
      if (data['data'] != null) {
        final entries = data['data'] as Map<String, dynamic>;
        final result = <String, UserActivity>{};
        for (final entry in entries.entries) {
          final activity = UserActivity.fromJson(
            entry.value as Map<String, dynamic>,
          );
          result[entry.key] = activity;
          _cache[entry.key] = activity;
          _cacheTimestamps[entry.key] = now;
        }
        return result;
      }
    } catch (e, st) {
      _log.warning('getBulkLastActivity() failed', e, st);
    }
    return {};
  }

  /// Leert den Cache.
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
