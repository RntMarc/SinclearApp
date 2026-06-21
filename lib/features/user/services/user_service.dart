// ignore_for_file: prefer_initializing_formals

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

  Future<List<UserBasePublic>> listAll() async {
    final data = await _api.get('/user', token: await _token());
    return UserListResponse.fromJson(data).data;
  }

  Future<UserDetailPublic> get(String userId) async {
    final data = await _api.get('/user/$userId', token: await _token());
    return UserDetailPublicResponse.fromJson(data).data;
  }
}
