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

  AuthService({
    required ApiClient api,
    required TokenStorage storage,
  })  : _api = api,
        _storage = storage;

  Future<void> init() async {
    _loggedIn = (await _storage.getRefreshToken()) != null;
    if (_loggedIn) {
      try {
        await getAccessToken();
      } catch (_) {
        _loggedIn = false;
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
    } catch (_) {
      return null;
    }
  }

  bool get isAdmin => userFromToken?['isAdmin'] == true;
  String? get userId => userFromToken?['sub'] as String?;

  Future<String> getAccessToken() async {
    if (_accessToken != null &&
        DateTime.now().millisecondsSinceEpoch ~/ 1000 < _accessTokenExpiry) {
      return _accessToken!;
    }
    if (_refreshFuture != null) return _refreshFuture!;
    _refreshFuture = _doRefresh();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String> _doRefresh() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null) {
      throw ApiException(errorCode: 'not_logged_in', statusCode: 401);
    }
    final data = await _api.post('/auth/refresh', body: {
      'refresh_token': refresh,
    });
    _accessToken = data['access_token'] as String;
    _accessTokenExpiry =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 +
            (data['expires_in'] as int);
    final newRefresh = data['refresh_token'] as String;
    await _storage.saveRefreshToken(
      newRefresh,
      data['expires_at'] as int? ?? 0,
    );
    return _accessToken!;
  }

  Future<void> requestOtp(String email) async {
    final body = OtpRequest(email: email).toJson();
    await _api.post('/auth/login/otp/request', body: body);
    developer.log('OTP requested for $email', name: 'auth');
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
    notifyListeners();
    developer.log('Code verified, refresh token saved', name: 'auth');
    return response;
  }

  Future<void> logout() async {
    _accessToken = null;
    _accessTokenExpiry = 0;
    _loggedIn = false;
    await _storage.clearTokens();
    notifyListeners();
    developer.log('User logged out', name: 'auth');
  }
}
