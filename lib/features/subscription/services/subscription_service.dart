import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/subscription_models.dart';

// ignore_for_file: prefer_initializing_formals

class SubscriptionService {
  final ApiClient _api;
  final AuthService _auth;

  SubscriptionService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  Future<List<Subscription>> list() async {
    final data = await _api.get('/subscriptions', token: await _token());
    final items = data['data'] as List<dynamic>;
    final subscriptions = items
        .map((item) => Subscription.fromJson(item as Map<String, dynamic>))
        .toList();
    return Subscription.deduplicate(subscriptions);
  }

  Future<Subscription> detail(String id) async {
    final data = await _api.get('/subscriptions/$id', token: await _token());
    return Subscription.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<SubscriptionParticipant>> participants(String id) async {
    final data = await _api.get(
      '/subscriptions/$id/participants',
      token: await _token(),
    );
    final items = data['data'] as List<dynamic>;
    return items
        .map(
          (item) =>
              SubscriptionParticipant.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
