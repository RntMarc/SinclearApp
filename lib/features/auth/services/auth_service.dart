// ignore_for_file: prefer_initializing_formals

import 'dart:developer' as developer;
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthService {
  final ApiClient _api;
  final TokenStorage _storage;

  AuthService({
    required ApiClient api,
    required TokenStorage storage,
  })  : _api = api,
        _storage = storage;

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
    developer.log('Code verified, refresh token saved', name: 'auth');
    return response;
  }

  Future<void> logout() async {
    await _storage.clearTokens();
    developer.log('User logged out', name: 'auth');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getRefreshToken();
    return token != null;
  }
}
