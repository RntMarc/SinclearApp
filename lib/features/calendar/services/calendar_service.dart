// ignore_for_file: prefer_initializing_formals

import '../../../core/network/api_client.dart';
import '../../../core/services/time_zone_service.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/services/auth_service.dart';
import '../models/calendar_models.dart';

class CalendarService {
  final ApiClient _api;
  final AuthService _auth;
  final TimeZoneService _timeZones;

  CalendarService({
    required ApiClient api,
    required AuthService auth,
    required TimeZoneService timeZones,
  }) : _api = api,
       _auth = auth,
       _timeZones = timeZones;

  Future<String> _token() => _auth.getAccessToken();

  Future<CalendarEventListResponse> list({
    int page = 1,
    int limit = 50,
    DateTime? start,
    DateTime? end,
    String? range,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'timezone': _timeZones.effective,
    };

    if (start != null && end != null) {
      params['start'] = toApiDateOnly(start);
      params['end'] = toApiDateOnly(end);
    } else if (range != null) {
      params['range'] = range;
    }

    final data = await _api.get(
      '/calendar',
      queryParams: params,
      token: await _token(),
    );
    return CalendarEventListResponse.fromJson(data);
  }

  Future<CalendarEvent> get(String id) async {
    final data = await _api.get('/calendar/$id', token: await _token());
    return CalendarEventDetailResponse.fromJson(data).data;
  }

  /// Kombinierter Feed (`GET /calendar/all`): echte Kalender-Events,
  /// Reise-Events, Reisen, Geburtstage und ÖPNV-Fahrten im Zeitraum
  /// [start]–[end] (beide oder keiner, sonst antwortet die API mit 400).
  /// [types] begrenzt die Quellen auf die angegebenen Typen. Die
  /// Zeitraumgrenzen werden in der effektiven Zeitzone des Nutzers ausgelegt.
  Future<CalendarAllResponse> all({
    DateTime? start,
    DateTime? end,
    List<String>? types,
  }) async {
    final params = <String, String>{'timezone': _timeZones.effective};
    if (start != null && end != null) {
      params['start'] = toApiDateOnly(start);
      params['end'] = toApiDateOnly(end);
    }
    if (types != null && types.isNotEmpty) {
      params['types'] = types.join(',');
    }

    final data = await _api.get(
      '/calendar/all',
      queryParams: params,
      token: await _token(),
    );
    return CalendarAllResponse.fromJson(data);
  }

  /// Erstellt ein Event. [startAt]/[endAt] sind Wandzeiten in [timezone]
  /// (getaktet), [startDate]/[endDate] zivile Tage (ganztägig).
  Future<CalendarEvent> create({
    required String title,
    String? description,
    required bool allDay,
    required String timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    int visibility = 0,
    List<String>? participantIds,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'allDay': allDay,
      'timezone': timezone,
      'visibility': visibility,
    };
    if (allDay) {
      if (startDate == null || endDate == null) {
        throw ArgumentError('startDate/endDate required for all-day events');
      }
      body['startDate'] = toApiDateOnly(startDate);
      body['endDate'] = toApiDateOnly(endDate);
    } else {
      if (startAt == null || endAt == null) {
        throw ArgumentError('startAt/endAt required for timed events');
      }
      body['startAt'] = toApiInstant(wallTimeToInstant(startAt, timezone), timezone);
      body['endAt'] = toApiInstant(wallTimeToInstant(endAt, timezone), timezone);
    }
    if (description != null) body['description'] = description;
    if (participantIds != null && participantIds.isNotEmpty) {
      body['participants'] = participantIds;
    }

    final data = await _api.post(
      '/calendar',
      body: body,
      token: await _token(),
    );
    return CalendarEventDetailResponse.fromJson(data).data;
  }

  /// Partielles Update. Getaktete Zeiten werden aus der Wandzeit in
  /// [timezone] in UTC-Instants mit Offset umgerechnet.
  Future<CalendarEvent> update(
    String id, {
    String? title,
    String? description,
    bool? allDay,
    String? timezone,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startAt,
    DateTime? endAt,
    int? visibility,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (visibility != null) body['visibility'] = visibility;
    final zone = timezone ?? 'UTC';
    if (timezone != null) body['timezone'] = timezone;
    if (allDay != null) {
      body['allDay'] = allDay;
      if (allDay) {
        if (startDate != null) body['startDate'] = toApiDateOnly(startDate);
        if (endDate != null) body['endDate'] = toApiDateOnly(endDate);
      } else {
        if (startAt != null) {
          body['startAt'] = toApiInstant(
            wallTimeToInstant(startAt, zone),
            zone,
          );
        }
        if (endAt != null) {
          body['endAt'] = toApiInstant(wallTimeToInstant(endAt, zone), zone);
        }
      }
    }

    final data = await _api.put(
      '/calendar/$id',
      body: body,
      token: await _token(),
    );
    return CalendarEventDetailResponse.fromJson(data).data;
  }

  Future<void> delete(String id) async {
    await _api.delete('/calendar/$id', token: await _token());
  }

  Future<void> addParticipant(String eventId, String userId) async {
    await _api.post(
      '/calendar/$eventId/participants',
      body: {'userId': userId},
      token: await _token(),
    );
  }

  Future<void> removeParticipant(String eventId, String userId) async {
    await _api.delete(
      '/calendar/$eventId/participants/$userId',
      token: await _token(),
    );
  }
}
