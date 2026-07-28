import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../../subscription/models/subscription_models.dart';
import '../models/travel_models.dart';

// ignore_for_file: prefer_initializing_formals

class TravelService {
  final ApiClient _api;
  final AuthService _auth;

  TravelService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  Future<TravelTripListResponse> list({int page = 1, int limit = 20}) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final data = await _api.get(
      '/trips',
      queryParams: params,
      token: await _token(),
    );
    return TravelTripListResponse.fromJson(data);
  }

  Future<TravelTrip> getTrip(String id) async {
    final data = await _api.get('/trips/$id', token: await _token());
    return TravelTrip.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TravelEventListResponse> getEvents(String tripId) async {
    final data = await _api.get('/trips/$tripId/events', token: await _token());
    return TravelEventListResponse.fromJson(data);
  }

  Future<TravelAccommodationListResponse> getAccommodations(
    String tripId,
  ) async {
    final data = await _api.get(
      '/trips/$tripId/accommodations',
      token: await _token(),
    );
    return TravelAccommodationListResponse.fromJson(data);
  }

  Future<TravelParticipantListResponse> getParticipants(String tripId) async {
    final data = await _api.get(
      '/trips/$tripId/participants',
      token: await _token(),
    );
    return TravelParticipantListResponse.fromJson(data);
  }

  Future<TravelStandaloneEventListResponse> getStandaloneEvents({
    int page = 1,
    int limit = 100,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final data = await _api.get(
      '/trips/standaloneevents',
      queryParams: params,
      token: await _token(),
    );
    return TravelStandaloneEventListResponse.fromJson(data);
  }

  Future<TravelEvent> getEventUnified(String eventId) async {
    final data = await _api.get(
      '/trips/events/$eventId',
      token: await _token(),
    );
    return TravelEvent.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TravelAccommodation> getAccommodationDetail(
    String tripId,
    String accommodationId,
  ) async {
    final data = await _api.get(
      '/trips/$tripId/accommodations/$accommodationId',
      token: await _token(),
    );
    return TravelAccommodation.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<TravelEventTicket>> getTripTickets(String tripId) async {
    final data = await _api.get(
      '/trips/$tripId/tickets',
      token: await _token(),
    );
    final items = data['data'] as List<dynamic>;
    return items
        .map((item) => TravelEventTicket.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TravelEventTicket>> getEventTickets(String eventId) async {
    final data = await _api.get(
      '/trips/events/$eventId/tickets',
      token: await _token(),
    );
    final items = data['data'] as List<dynamic>;
    return items
        .map((item) => TravelEventTicket.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TravelEventTicket>> listUserTickets() async {
    final data = await _api.get('/trips/tickets/user', token: await _token());
    final items = data['data'] as List<dynamic>;
    return items
        .map((item) => TravelEventTicket.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TravelEventTicket> createUserTicket({
    String? qrcode,
    String? image,
    String? eventId,
    String? tripId,
  }) async {
    final body = <String, dynamic>{};
    if (qrcode != null) body['qrcode'] = qrcode;
    if (image != null) body['image'] = image;
    if (eventId != null) body['event'] = eventId;
    if (tripId != null) body['trip'] = tripId;

    final data = await _api.post(
      '/trips/tickets/user',
      body: body,
      token: await _token(),
    );
    return TravelEventTicket.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TravelEventTicket> updateUserTicket(
    String ticketId, {
    String? qrcode,
    String? image,
    String? eventId,
    String? tripId,
  }) async {
    final body = <String, dynamic>{};
    if (qrcode != null) body['qrcode'] = qrcode;
    if (image != null) body['image'] = image;
    if (eventId != null) body['event'] = eventId;
    if (tripId != null) body['trip'] = tripId;

    final data = await _api.put(
      '/trips/tickets/user/$ticketId',
      body: body,
      token: await _token(),
    );
    return TravelEventTicket.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteUserTicket(String ticketId) async {
    await _api.delete('/trips/tickets/user/$ticketId', token: await _token());
  }

  Future<List<Subscription>> getTripSubscriptions(String tripId) async {
    final data = await _api.get(
      '/trips/$tripId/subscriptions',
      token: await _token(),
    );
    final items = data['data'] as List<dynamic>;
    return items
        .map((item) => Subscription.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
