// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/user_models.dart';

class UserService {
  final ApiClient _api;
  final AuthService _auth;

  UserService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  // ─── Public / other users ─────────────────────────────────────────────

  Future<List<UserBasePublic>> listAll() async {
    final data = await _api.get('/user', token: await _token());
    return UserListResponse.fromJson(data).data;
  }

  Future<UserDetailPublic> get(String userId) async {
    final data = await _api.get('/user/$userId', token: await _token());
    return UserDetailPublicResponse.fromJson(data).data;
  }

  // ─── Own profile (private) ────────────────────────────────────────────

  Future<UserMe> getMe() async {
    final data = await _api.get('/user/me', token: await _token());
    return UserMe.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<UserBase> getMeBase() async {
    final data = await _api.get('/user/me/base', token: await _token());
    return UserBase.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<UserSocialInfo> getMeSocial() async {
    final data = await _api.get('/user/me/social', token: await _token());
    return UserSocialInfo.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<UserContactInfo> getMeContact() async {
    final data = await _api.get('/user/me/contact', token: await _token());
    return UserContactInfo.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ─── Write ────────────────────────────────────────────────────────────

  Future<UserMe> updateProfile(ProfileUpdateRequest request) async {
    final json = request.toJson();
    if (kDebugMode) {
      final imagePreview = json['image'] is String
          ? 'len=${(json['image'] as String).length} preview=${(json['image'] as String).substring(0, 80)}...'
          : '${json['image']}';
      debugPrint(
        '[user_service] PUT /user/me/profile image=$imagePreview removeImage=${json['removeImage']} birthday=${json['birthday']}',
      );
    }
    final data = await _api.put(
      '/user/me/profile',
      body: json,
      token: await _token(),
    );
    if (kDebugMode) {
      final responseImage = data['data']?['image'];
      debugPrint(
        '[user_service] Response received image=${responseImage is String ? 'len=${responseImage.length} preview=${responseImage.substring(0, 80)}...' : '$responseImage'}',
      );
    }
    return UserMe.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> updateVisibility(VisibilityUpdateRequest request) async {
    await _api.put(
      '/user/me/visibility',
      body: request.toJson(),
      token: await _token(),
    );
  }

  Future<void> requestEmailChange(String newEmail) async {
    final body = EmailChangeRequest(newEmail: newEmail).toJson();
    await _api.post(
      '/user/me/email/request',
      body: body,
      token: await _token(),
    );
  }

  Future<void> verifyEmailChange(String code, String newEmail) async {
    final body = EmailChangeVerifyRequest(
      code: code,
      newEmail: newEmail,
    ).toJson();
    await _api.post('/user/me/email/verify', body: body, token: await _token());
  }

  Future<String> discordRelinkStart() async {
    final data = await _api.post(
      '/user/me/discord/start',
      token: await _token(),
    );
    return (data['url'] as String);
  }

  Future<void> discordRelinkVerify(String code) async {
    final body = DiscordVerifyRequest(code: code).toJson();
    await _api.post(
      '/user/me/discord/verify',
      body: body,
      token: await _token(),
    );
  }

  Future<UserPreferences> getPreferences() async {
    final data = await _api.get('/user/me/preferences', token: await _token());
    return UserPreferencesResponse.fromJson(data).data;
  }

  Future<UserPreferences> updatePreferences(Map<String, dynamic> body) async {
    final data = await _api.put(
      '/user/me/preferences',
      body: body,
      token: await _token(),
    );
    return UserPreferencesResponse.fromJson(data).data;
  }
}
