import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
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
    String? title,
    String? qrcode,
    String? image,
    String? eventId,
    String? tripId,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
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
    String? title,
    String? qrcode,
    String? image,
    String? eventId,
    String? tripId,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
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

  // ──────────────────────────── Reise schreiben ────────────────────────────

  Future<TravelTrip> createTrip({
    required String name,
    String? description,
    required bool allDay,
    required String timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    bool hastickets = false,
    String? ticket,
    String? ticketUrl,
  }) async {
    final data = await _api.post(
      '/trips',
      body: _tripWriteBody(
        name: name,
        description: description,
        allDay: allDay,
        timezone: timezone,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
        hastickets: hastickets,
        ticket: ticket,
        ticketUrl: ticketUrl,
      ),
      token: await _token(),
    );
    return TravelTrip.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TravelTrip> updateTrip(
    String id, {
    String? name,
    String? description,
    bool? allDay,
    String? timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    bool? hastickets,
    String? ticket,
    String? ticketUrl,
  }) async {
    final data = await _api.patch(
      '/trips/$id',
      body: _tripWriteBody(
        name: name,
        description: description,
        allDay: allDay,
        timezone: timezone,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
        hastickets: hastickets,
        ticket: ticket,
        ticketUrl: ticketUrl,
      ),
      token: await _token(),
    );
    return TravelTrip.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTrip(String id) async {
    await _api.delete('/trips/$id', token: await _token());
  }

  // ──────────────────────────── Events schreiben ────────────────────────────

  Future<TravelEvent> createTripEvent(
    String tripId, {
    required String name,
    String? description,
    required bool allDay,
    required String timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    bool hastickets = false,
    String? ticket,
    String? ticketUrl,
    String? url,
    String? image,
    String? organizer,
    String? address,
    double? latitude,
    double? longitude,
    int? osmId,
    String? citySlug,
  }) async {
    final data = await _api.post(
      '/trips/$tripId/events',
      body: _eventWriteBody(
        name: name,
        description: description,
        allDay: allDay,
        timezone: timezone,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
        hastickets: hastickets,
        ticket: ticket,
        ticketUrl: ticketUrl,
        url: url,
        image: image,
        organizer: organizer,
        address: address,
        latitude: latitude,
        longitude: longitude,
        osmId: osmId,
        citySlug: citySlug,
      ),
      token: await _token(),
    );
    return TravelEvent.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TravelEvent> updateTripEvent(
    String tripId,
    String eventId, {
    String? name,
    String? description,
    bool? allDay,
    String? timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    bool? hastickets,
    String? ticket,
    String? ticketUrl,
    String? url,
    String? image,
    String? organizer,
    String? address,
    double? latitude,
    double? longitude,
    int? osmId,
    String? citySlug,
  }) async {
    final data = await _api.patch(
      '/trips/$tripId/events/$eventId',
      body: _eventWriteBody(
        name: name,
        description: description,
        allDay: allDay,
        timezone: timezone,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
        hastickets: hastickets,
        ticket: ticket,
        ticketUrl: ticketUrl,
        url: url,
        image: image,
        organizer: organizer,
        address: address,
        latitude: latitude,
        longitude: longitude,
        osmId: osmId,
        citySlug: citySlug,
      ),
      token: await _token(),
    );
    return TravelEvent.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTripEvent(String tripId, String eventId) async {
    await _api.delete('/trips/$tripId/events/$eventId', token: await _token());
  }

  /// Löst ein Reise-Event zu einem Standalone-Event (`trip: null`).
  Future<TravelEvent> detachTripEvent(String tripId, String eventId) async {
    final data = await _api.patch(
      '/trips/$tripId/events/$eventId',
      body: const {'trip': null},
      token: await _token(),
    );
    return TravelEvent.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TravelEvent> createStandaloneEvent({
    required String name,
    String? description,
    required bool allDay,
    required String timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    bool hastickets = false,
    String? ticket,
    String? ticketUrl,
    String? url,
    String? image,
    String? organizer,
    String? address,
    double? latitude,
    double? longitude,
    int? osmId,
    String? citySlug,
  }) async {
    final data = await _api.post(
      '/trips/standaloneevents',
      body: _eventWriteBody(
        name: name,
        description: description,
        allDay: allDay,
        timezone: timezone,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
        hastickets: hastickets,
        ticket: ticket,
        ticketUrl: ticketUrl,
        url: url,
        image: image,
        organizer: organizer,
        address: address,
        latitude: latitude,
        longitude: longitude,
        osmId: osmId,
        citySlug: citySlug,
      ),
      token: await _token(),
    );
    return TravelEvent.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TravelEvent> updateStandaloneEvent(
    String eventId, {
    String? name,
    String? description,
    bool? allDay,
    String? timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    bool? hastickets,
    String? ticket,
    String? ticketUrl,
    String? url,
    String? image,
    String? organizer,
    String? address,
    double? latitude,
    double? longitude,
    int? osmId,
    String? citySlug,
  }) async {
    final data = await _api.patch(
      '/trips/standaloneevents/$eventId',
      body: _eventWriteBody(
        name: name,
        description: description,
        allDay: allDay,
        timezone: timezone,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
        hastickets: hastickets,
        ticket: ticket,
        ticketUrl: ticketUrl,
        url: url,
        image: image,
        organizer: organizer,
        address: address,
        latitude: latitude,
        longitude: longitude,
        osmId: osmId,
        citySlug: citySlug,
      ),
      token: await _token(),
    );
    return TravelEvent.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Hängt ein Standalone-Event an eine Reise an (`trip` gesetzt).
  Future<TravelEvent> attachStandaloneEvent(
    String eventId,
    String tripId,
  ) async {
    final data = await _api.patch(
      '/trips/standaloneevents/$eventId',
      body: {'trip': tripId},
      token: await _token(),
    );
    return TravelEvent.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteStandaloneEvent(String eventId) async {
    await _api.delete(
      '/trips/standaloneevents/$eventId',
      token: await _token(),
    );
  }

  // ──────────────────────────── Unterkünfte schreiben ────────────────────────────

  Future<TravelAccommodation> createAccommodation(
    String tripId, {
    required String name,
    String? description,
    String? address,
    String? phone,
    String? mail,
    bool isHotel = false,
    double? latitude,
    double? longitude,
    int? osmId,
    String? citySlug,
  }) async {
    final data = await _api.post(
      '/trips/$tripId/accommodations',
      body: _accommodationWriteBody(
        name: name,
        description: description,
        address: address,
        phone: phone,
        mail: mail,
        isHotel: isHotel,
        latitude: latitude,
        longitude: longitude,
        osmId: osmId,
        citySlug: citySlug,
      ),
      token: await _token(),
    );
    return TravelAccommodation.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TravelAccommodation> updateAccommodation(
    String tripId,
    String accommodationId, {
    String? name,
    String? description,
    String? address,
    String? phone,
    String? mail,
    bool? isHotel,
    double? latitude,
    double? longitude,
    int? osmId,
    String? citySlug,
  }) async {
    final data = await _api.patch(
      '/trips/$tripId/accommodations/$accommodationId',
      body: _accommodationWriteBody(
        name: name,
        description: description,
        address: address,
        phone: phone,
        mail: mail,
        isHotel: isHotel,
        latitude: latitude,
        longitude: longitude,
        osmId: osmId,
        citySlug: citySlug,
      ),
      token: await _token(),
    );
    return TravelAccommodation.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAccommodation(
    String tripId,
    String accommodationId,
  ) async {
    await _api.delete(
      '/trips/$tripId/accommodations/$accommodationId',
      token: await _token(),
    );
  }

  /// Globaler Katalog wiederverwendbarer Unterkünfte, optional nach Name
  /// gefiltert.
  Future<List<TravelAccommodation>> listAccommodationCatalog({
    String? query,
  }) async {
    final trimmed = query?.trim() ?? '';
    final data = await _api.get(
      '/trips/accommodations',
      queryParams: trimmed.isEmpty ? null : {'q': trimmed},
      token: await _token(),
    );
    return (data['data'] as List)
        .map((e) => TravelAccommodation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Verknüpft eine bereits vorhandene Katalog-Unterkunft mit der Reise.
  Future<TravelAccommodation> linkAccommodation(
    String tripId,
    String accommodationId,
  ) async {
    final data = await _api.post(
      '/trips/$tripId/accommodations',
      body: {'accommodationId': accommodationId},
      token: await _token(),
    );
    return TravelAccommodation.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Weist einem Teilnehmer eine Unterkunft zu (oder hebt sie mit `null` auf).
  Future<void> assignParticipantAccommodation(
    String tripId,
    String userId, {
    String? accommodationId,
  }) async {
    await _api.put(
      '/trips/$tripId/participants/$userId/accommodation',
      body: {'accommodation': accommodationId},
      token: await _token(),
    );
  }

  /// Entfernt eine Unterkunft endgültig aus dem globalen Katalog.
  Future<void> deleteAccommodationGlobal(String accommodationId) async {
    await _api.delete(
      '/trips/accommodations/$accommodationId',
      token: await _token(),
    );
  }

  Future<void> addTripEventParticipant(
    String tripId,
    String eventId,
    String userId,
  ) async {
    await _api.post(
      '/trips/$tripId/events/$eventId/participants',
      body: {'userId': userId},
      token: await _token(),
    );
  }

  Future<void> removeTripEventParticipant(
    String tripId,
    String eventId,
    String userId,
  ) async {
    await _api.delete(
      '/trips/$tripId/events/$eventId/participants/$userId',
      token: await _token(),
    );
  }

  // ──────────────────────────── Teilnehmer & Rollen ────────────────────────────

  Future<void> addTripParticipant(
    String tripId,
    String userId, {
    String? accommodation,
  }) async {
    await _api.post(
      '/trips/$tripId/participants',
      body: {'userId': userId, 'accommodation': ?accommodation},
      token: await _token(),
    );
  }

  Future<void> removeTripParticipant(String tripId, String userId) async {
    await _api.delete(
      '/trips/$tripId/participants/$userId',
      token: await _token(),
    );
  }

  Future<void> setTripParticipantRole(
    String tripId,
    String userId,
    String role,
  ) async {
    await _api.put(
      '/trips/$tripId/participants/$userId/role',
      body: {'role': role},
      token: await _token(),
    );
  }

  Future<void> addStandaloneEventParticipant(
    String eventId,
    String userId,
  ) async {
    await _api.post(
      '/trips/standaloneevents/$eventId/participants',
      body: {'userId': userId},
      token: await _token(),
    );
  }

  Future<void> removeStandaloneEventParticipant(
    String eventId,
    String userId,
  ) async {
    await _api.delete(
      '/trips/standaloneevents/$eventId/participants/$userId',
      token: await _token(),
    );
  }

  Future<void> setStandaloneEventParticipantRole(
    String eventId,
    String userId,
    String role,
  ) async {
    await _api.put(
      '/trips/standaloneevents/$eventId/participants/$userId/role',
      body: {'role': role},
      token: await _token(),
    );
  }

  // ──────────────────────────── Request-Builder ────────────────────────────

  Map<String, dynamic> _tripWriteBody({
    String? name,
    String? description,
    bool? allDay,
    String? timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    bool? hastickets,
    String? ticket,
    String? ticketUrl,
  }) {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    body.addAll(
      _timingBody(
        allDay: allDay,
        timezone: timezone,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
      ),
    );
    if (hastickets != null) body['hastickets'] = hastickets ? '1' : '0';
    if (ticket != null) body['ticket'] = ticket;
    if (ticketUrl != null) body['ticketUrl'] = ticketUrl;
    return body;
  }

  Map<String, dynamic> _eventWriteBody({
    String? name,
    String? description,
    bool? allDay,
    String? timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    bool? hastickets,
    String? ticket,
    String? ticketUrl,
    String? url,
    String? image,
    String? organizer,
    String? address,
    double? latitude,
    double? longitude,
    int? osmId,
    String? citySlug,
  }) {
    final body = _tripWriteBody(
      name: name,
      description: description,
      allDay: allDay,
      timezone: timezone,
      startDate: startDate,
      endDate: endDate,
      startAt: startAt,
      endAt: endAt,
      hastickets: hastickets,
      ticket: ticket,
      ticketUrl: ticketUrl,
    );
    if (url != null) body['url'] = url;
    if (image != null) body['image'] = image;
    if (organizer != null) body['organizer'] = organizer;
    if (address != null) body['address'] = address;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (osmId != null) body['OSMID'] = osmId;
    if (citySlug != null) body['citySlug'] = citySlug;
    return body;
  }

  Map<String, dynamic> _accommodationWriteBody({
    String? name,
    String? description,
    String? address,
    String? phone,
    String? mail,
    bool? isHotel,
    double? latitude,
    double? longitude,
    int? osmId,
    String? citySlug,
  }) {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (address != null) body['address'] = address;
    if (phone != null) body['phone'] = phone;
    if (mail != null) body['mail'] = mail;
    if (isHotel != null) body['ishotel'] = isHotel ? 1 : 0;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (osmId != null) body['OSMID'] = osmId;
    if (citySlug != null) body['citySlug'] = citySlug;
    return body;
  }

  Map<String, dynamic> _timingBody({
    bool? allDay,
    String? timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
  }) {
    final body = <String, dynamic>{};
    if (allDay != null) body['allDay'] = allDay;
    if (timezone != null) body['timezone'] = timezone;
    if (allDay == true) {
      if (startDate != null) body['startDate'] = toApiDateOnly(startDate);
      if (endDate != null) body['endDate'] = toApiDateOnly(endDate);
    } else if (allDay == false) {
      final zone = timezone ?? 'UTC';
      if (startAt != null) {
        body['startAt'] = toApiInstant(wallTimeToInstant(startAt, zone), zone);
      }
      if (endAt != null) {
        body['endAt'] = toApiInstant(wallTimeToInstant(endAt, zone), zone);
      }
    }
    return body;
  }
}
