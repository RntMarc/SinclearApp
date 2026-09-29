import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/services/auth_service.dart';
import '../models/travel_planning_models.dart';

// ignore_for_file: prefer_initializing_formals

/// API-Anbindung der Reiseplanung (`/trips/planning`, Phase 2).
///
/// Getrennt vom operativen [TravelService], damit die Planungslogik
/// unabhängig von `TravelRelation` bleibt. Alle Endpunkte verlangen einen
/// gültigen JWT. Die Zeitfelder folgen der zeitzonen-bewussten Konvention:
/// ganztägig `startDate`/`endDate` (zivile Tage), getaktet `startAt`/`endAt`
/// als RFC-3339-Instant plus `timezone`.
class TravelPlanningService {
  final ApiClient _api;
  final AuthService _auth;

  TravelPlanningService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  // ──────────────────────────── Reisen ────────────────────────────

  Future<PlanningTripListResponse> list({int page = 1, int limit = 20}) async {
    final data = await _api.get(
      '/trips/planning',
      queryParams: {'page': '$page', 'limit': '$limit'},
      token: await _token(),
    );
    return PlanningTripListResponse.fromJson(data);
  }

  Future<PlanningTripDetail> create({
    required String name,
    String? description,
    List<String>? skippedTopics,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;
    if (skippedTopics != null && skippedTopics.isNotEmpty) {
      body['skippedTopics'] = skippedTopics;
    }
    final data = await _api.post(
      '/trips/planning',
      body: body,
      token: await _token(),
    );
    return PlanningTripDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PlanningTripDetail> getDetail(String id) async {
    final data = await _api.get('/trips/planning/$id', token: await _token());
    return PlanningTripDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PlanningTripDetail> update(
    String id, {
    String? name,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    final data = await _api.patch(
      '/trips/planning/$id',
      body: body,
      token: await _token(),
    );
    return PlanningTripDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PlanningTripDetail> activate(String id) async {
    final data = await _api.post(
      '/trips/planning/$id/activate',
      token: await _token(),
    );
    return PlanningTripDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ──────────────────────────── Mitglieder ────────────────────────────

  Future<List<PlanMember>> listMembers(String id) async {
    final data = await _api.get(
      '/trips/planning/$id/members',
      token: await _token(),
    );
    return _mapList(data['data'], PlanMember.fromJson);
  }

  Future<void> inviteMember(String id, String userId) async {
    await _api.post(
      '/trips/planning/$id/members',
      body: {'userId': userId},
      token: await _token(),
    );
  }

  /// Eigene Rückmeldung (`accepted`/`declined`).
  Future<void> respond(String id, String response) async {
    await _api.put(
      '/trips/planning/$id/members/me',
      body: {'response': response},
      token: await _token(),
    );
  }

  /// Mitglied aktiv/inaktiv setzen (Leitung): `accepted`/`inactive`.
  Future<void> setMemberStatus(String id, String userId, String status) async {
    await _api.patch(
      '/trips/planning/$id/members/$userId',
      body: {'status': status},
      token: await _token(),
    );
  }

  Future<void> removeMember(String id, String userId) async {
    await _api.delete(
      '/trips/planning/$id/members/$userId',
      token: await _token(),
    );
  }

  // ──────────────────────────── Themen ────────────────────────────

  Future<List<PlanTopic>> setTopicStatus(
    String id,
    String topic,
    String status,
  ) async {
    final data = await _api.patch(
      '/trips/planning/$id/topics/$topic',
      body: {'status': status},
      token: await _token(),
    );
    return _mapList(data['data'], PlanTopic.fromJson);
  }

  // ──────────────────────────── Terminoptionen ────────────────────────────

  Future<List<PlanDateOption>> listDateOptions(String id) async {
    final data = await _api.get(
      '/trips/planning/$id/dates',
      token: await _token(),
    );
    return _mapList(data['data'], PlanDateOption.fromJson);
  }

  Future<PlanDateOption> createDateOption(
    String id, {
    String? label,
    required bool allDay,
    required String timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final body = <String, dynamic>{
      'label': ?label,
      ..._timingBody(
        allDay: allDay,
        timezone: timezone,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
      ),
    };
    final data = await _api.post(
      '/trips/planning/$id/dates',
      body: body,
      token: await _token(),
    );
    return PlanDateOption.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PlanDateOption> updateDateOption(
    String id,
    String optionId, {
    String? label,
    bool? allDay,
    String? timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final body = <String, dynamic>{
      'label': ?label,
      ..._timingBody(
        allDay: allDay,
        timezone: timezone,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
      ),
    };
    final data = await _api.patch(
      '/trips/planning/$id/dates/$optionId',
      body: body,
      token: await _token(),
    );
    return PlanDateOption.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteDateOption(String id, String optionId) async {
    await _api.delete(
      '/trips/planning/$id/dates/$optionId',
      token: await _token(),
    );
  }

  /// Eigene Verfügbarkeit (`yes`/`maybe`/`no`).
  Future<PlanDateOption> setDateResponse(
    String id,
    String optionId,
    String availability,
  ) async {
    final data = await _api.put(
      '/trips/planning/$id/dates/$optionId/responses',
      body: {'availability': availability},
      token: await _token(),
    );
    return PlanDateOption.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PlanDateOption> finalizeDate(String id, String optionId) async {
    final data = await _api.post(
      '/trips/planning/$id/dates/$optionId/finalize',
      token: await _token(),
    );
    return PlanDateOption.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ──────────────────────────── Transport ────────────────────────────

  Future<List<PlanTransport>> listTransport(String id) async {
    final data = await _api.get(
      '/trips/planning/$id/transport',
      token: await _token(),
    );
    return _mapList(data['data'], PlanTransport.fromJson);
  }

  Future<PlanTransport> setTransport(
    String id, {
    String direction = 'outbound',
    String? mode,
    bool? offersRide,
    int? availableSeats,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'direction': direction,
      'mode': ?mode,
      'offersRide': ?offersRide,
      'availableSeats': ?availableSeats,
      'notes': ?notes,
    };
    final data = await _api.put(
      '/trips/planning/$id/transport',
      body: body,
      token: await _token(),
    );
    return PlanTransport.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ──────────────────────────── Unterkunftsoptionen ────────────────────────────

  Future<List<PlanAccommodationOption>> listAccommodationOptions(
    String id,
  ) async {
    final data = await _api.get(
      '/trips/planning/$id/accommodations',
      token: await _token(),
    );
    return _mapList(data['data'], PlanAccommodationOption.fromJson);
  }

  Future<PlanAccommodationOption> createAccommodationOption(
    String id, {
    String? accommodationId,
    String? name,
    String? description,
    String? address,
    int? osmId,
    double? latitude,
    double? longitude,
    String? citySlug,
    double? pricePerPersonPerNight,
    String? currency,
  }) async {
    final data = await _api.post(
      '/trips/planning/$id/accommodations',
      body: _accommodationBody(
        accommodationId: accommodationId,
        name: name,
        description: description,
        address: address,
        osmId: osmId,
        latitude: latitude,
        longitude: longitude,
        citySlug: citySlug,
        pricePerPersonPerNight: pricePerPersonPerNight,
        currency: currency,
      ),
      token: await _token(),
    );
    return PlanAccommodationOption.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }

  Future<PlanAccommodationOption> updateAccommodationOption(
    String id,
    String optionId, {
    String? name,
    String? description,
    String? address,
    int? osmId,
    double? latitude,
    double? longitude,
    String? citySlug,
    double? pricePerPersonPerNight,
    String? currency,
  }) async {
    final data = await _api.patch(
      '/trips/planning/$id/accommodations/$optionId',
      body: _accommodationBody(
        name: name,
        description: description,
        address: address,
        osmId: osmId,
        latitude: latitude,
        longitude: longitude,
        citySlug: citySlug,
        pricePerPersonPerNight: pricePerPersonPerNight,
        currency: currency,
      ),
      token: await _token(),
    );
    return PlanAccommodationOption.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteAccommodationOption(String id, String optionId) async {
    await _api.delete(
      '/trips/planning/$id/accommodations/$optionId',
      token: await _token(),
    );
  }

  Future<PlanAccommodationOption> selectAccommodation(
    String id,
    String optionId,
  ) async {
    final data = await _api.post(
      '/trips/planning/$id/accommodations/$optionId/select',
      token: await _token(),
    );
    return PlanAccommodationOption.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }

  // ──────────────────────────── Eventvorschläge ────────────────────────────

  Future<List<PlanEventSuggestion>> listEventSuggestions(String id) async {
    final data = await _api.get(
      '/trips/planning/$id/events',
      token: await _token(),
    );
    return _mapList(data['data'], PlanEventSuggestion.fromJson);
  }

  Future<PlanEventSuggestion> createEventSuggestion(
    String id, {
    required String name,
    String? description,
    int dayIndex = 0,
    required bool allDay,
    required String timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    String? address,
    double? latitude,
    double? longitude,
    int? osmId,
    String? citySlug,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': ?description,
      'dayIndex': dayIndex,
      ..._timingBody(
        allDay: allDay,
        timezone: timezone,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
      ),
      'address': ?address,
      'latitude': ?latitude,
      'longitude': ?longitude,
      'OSMID': ?osmId,
      'citySlug': ?citySlug,
    };
    final data = await _api.post(
      '/trips/planning/$id/events',
      body: body,
      token: await _token(),
    );
    return PlanEventSuggestion.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PlanEventSuggestion> updateEventSuggestion(
    String id,
    String suggestionId, {
    String? name,
    String? description,
    int? dayIndex,
    bool? allDay,
    String? timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    String? address,
    double? latitude,
    double? longitude,
    int? osmId,
    String? citySlug,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'description': ?description,
      'dayIndex': ?dayIndex,
      ..._timingBody(
        allDay: allDay,
        timezone: timezone,
        startDate: startDate,
        endDate: endDate,
        startAt: startAt,
        endAt: endAt,
      ),
      'address': ?address,
      'latitude': ?latitude,
      'longitude': ?longitude,
      'OSMID': ?osmId,
      'citySlug': ?citySlug,
    };
    final data = await _api.patch(
      '/trips/planning/$id/events/$suggestionId',
      body: body,
      token: await _token(),
    );
    return PlanEventSuggestion.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteEventSuggestion(String id, String suggestionId) async {
    await _api.delete(
      '/trips/planning/$id/events/$suggestionId',
      token: await _token(),
    );
  }

  /// Eigenes Interesse (`yes`/`maybe`/`no`).
  Future<PlanEventSuggestion> setEventInterest(
    String id,
    String suggestionId,
    String interest,
  ) async {
    final data = await _api.put(
      '/trips/planning/$id/events/$suggestionId/interest',
      body: {'interest': interest},
      token: await _token(),
    );
    return PlanEventSuggestion.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<PlanEventSuggestion> confirmEvent(
    String id,
    String suggestionId, {
    bool confirmed = true,
  }) async {
    final data = await _api.post(
      '/trips/planning/$id/events/$suggestionId/confirm',
      body: {'confirmed': confirmed},
      token: await _token(),
    );
    return PlanEventSuggestion.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ──────────────────────────── Request-Builder ────────────────────────────

  Map<String, dynamic> _accommodationBody({
    String? accommodationId,
    String? name,
    String? description,
    String? address,
    int? osmId,
    double? latitude,
    double? longitude,
    String? citySlug,
    double? pricePerPersonPerNight,
    String? currency,
  }) {
    final body = <String, dynamic>{};
    if (accommodationId != null) body['accommodationId'] = accommodationId;
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (address != null) body['address'] = address;
    if (osmId != null) body['OSMID'] = osmId;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (citySlug != null) body['citySlug'] = citySlug;
    if (pricePerPersonPerNight != null) {
      body['pricePerPersonPerNight'] = pricePerPersonPerNight;
    }
    if (currency != null) body['currency'] = currency;
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

List<T> _mapList<T>(Object? raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList(growable: false);
}
