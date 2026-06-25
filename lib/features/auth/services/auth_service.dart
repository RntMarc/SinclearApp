// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _api;
  final TokenStorage _storage;

  String? _accessToken;
  int _accessTokenExpiry = 0;
  bool _loggedIn = false;
  Future<String>? _refreshFuture;

  bool get isLoggedIn => _loggedIn;

  AuthService({required ApiClient api, required TokenStorage storage})
    : _api = api,
      _storage = storage;

  Future<void> init() async {
    final hasRefresh = (await _storage.getRefreshToken()) != null;
    if (kDebugMode) {
      developer.log('init: hasRefreshToken=$hasRefresh', name: 'auth');
    }
    _loggedIn = hasRefresh;
    if (_loggedIn) {
      try {
        await getAccessToken();
        if (kDebugMode) {
          developer.log('init: pre-fetch access token succeeded', name: 'auth');
        }
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          _loggedIn = false;
          if (kDebugMode) {
            developer.log('init: pre-fetch 401 -> loggedOut', name: 'auth');
          }
        } else {
          if (kDebugMode) {
            developer.log(
              'init: pre-fetch ApiException: ${e.errorCode} ${e.statusCode}',
              name: 'auth',
            );
          }
        }
      } catch (e, s) {
        if (kDebugMode) {
          developer.log('init: pre-fetch error: $e\n$s', name: 'auth');
        }
      }
    }
    notifyListeners();
  }

  Map<String, dynamic>? get userFromToken {
    if (_accessToken == null) return null;
    try {
      final parts = _accessToken!.split('.');
      if (parts.length != 3) return null;
      final normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      final padded = normalized.padRight(
        normalized.length + (4 - normalized.length % 4) % 4,
        '=',
      );
      return jsonDecode(utf8.decode(base64.decode(padded)))
          as Map<String, dynamic>;
    } catch (e, st) {
      developer.log('Failed to decode user token', error: e, stackTrace: st);
      return null;
    }
  }

  bool get isAdmin => userFromToken?['isAdmin'] == true;
  String? get userId => userFromToken?['sub'] as String?;

  Future<String> getAccessToken() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (_accessToken != null && now < _accessTokenExpiry) {
      if (kDebugMode) {
        developer.log(
          'getAccessToken: returning cached token (expires in ${_accessTokenExpiry - now}s)',
          name: 'auth',
        );
      }
      return _accessToken!;
    }
    if (_refreshFuture != null) {
      if (kDebugMode) {
        developer.log(
          'getAccessToken: waiting for existing refreshFuture',
          name: 'auth',
        );
      }
      return _refreshFuture!;
    }
    if (kDebugMode) {
      developer.log('getAccessToken: starting new refresh', name: 'auth');
    }
    _refreshFuture = _doRefresh();
    try {
      final token = await _refreshFuture!;
      if (kDebugMode) {
        developer.log('getAccessToken: refresh completed', name: 'auth');
      }
      return token;
    } finally {
      _refreshFuture = null;
      if (kDebugMode) {
        developer.log('getAccessToken: refreshFuture cleared', name: 'auth');
      }
    }
  }

  Future<String> _doRefresh() async {
    if (kDebugMode) {
      developer.log(
        '_doRefresh: loading refresh token from storage',
        name: 'auth',
      );
    }
    final refresh = await _storage.getRefreshToken();
    if (refresh == null) {
      if (kDebugMode) {
        developer.log('_doRefresh: no refresh token in storage', name: 'auth');
      }
      throw ApiException(errorCode: 'not_logged_in', statusCode: 401);
    }
    if (kDebugMode) {
      developer.log('_doRefresh: calling /auth/refresh', name: 'auth');
    }
    final data = await _api.post(
      '/auth/refresh',
      body: {'refresh_token': refresh},
    );
    _accessToken = data['access_token'] as String;
    _accessTokenExpiry =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        (data['expires_in'] as int);
    final newRefresh = data['refresh_token'] as String;
    await _storage.saveRefreshToken(
      newRefresh,
      data['expires_at'] as int? ?? 0,
    );
    if (kDebugMode) {
      developer.log(
        '_doRefresh: success, token expires in ${data['expires_in']}s',
        name: 'auth',
      );
    }
    return _accessToken!;
  }

  Future<void> requestOtp(String email) async {
    final body = OtpRequest(email: email).toJson();
    await _api.post('/auth/login/otp/request', body: body);
    if (kDebugMode) developer.log('OTP requested for $email', name: 'auth');
  }

  Future<DiscordStartResponse> discordStart() async {
    final data = await _api.post('/auth/login/discord/start');
    return DiscordStartResponse.fromJson(data);
  }

  Future<RefreshTokenResponse> verifyCode({
    String? email,
    required String code,
  }) async {
    final body = OtpVerifyRequest(email: email, code: code).toJson();
    final data = await _api.post('/auth/login/otp/verify', body: body);
    final response = RefreshTokenResponse.fromJson(data);
    await _storage.saveRefreshToken(response.refreshToken, response.expiresAt);
    _loggedIn = true;
    if (kDebugMode) {
      developer.log(
        'verifyCode: refresh token saved, starting pre-fetch',
        name: 'auth',
      );
    }
    try {
      await getAccessToken();
      if (kDebugMode) {
        developer.log('verifyCode: pre-fetch succeeded', name: 'auth');
      }
    } catch (e, s) {
      if (kDebugMode) {
        developer.log('verifyCode: pre-fetch failed: $e\n$s', name: 'auth');
      }
    }
    notifyListeners();
    if (kDebugMode) {
      developer.log('Code verified, refresh token saved', name: 'auth');
    }
    return response;
  }

  Future<void> logout() async {
    if (kDebugMode) developer.log('logout: clearing tokens', name: 'auth');
    _accessToken = null;
    _accessTokenExpiry = 0;
    _loggedIn = false;
    await _storage.clearTokens();
    notifyListeners();
    if (kDebugMode) developer.log('User logged out', name: 'auth');
  }
}
