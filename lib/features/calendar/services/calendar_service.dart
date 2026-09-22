import 'package:flutter/material.dart' show TimeOfDay;
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/services/auth_service.dart';
import '../models/calendar_models.dart';

class CalendarService {
  final ApiClient _api;
  final AuthService _auth;

  CalendarService({required this._api, required this._auth});

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
  /// [types] begrenzt die Quellen auf die angegebenen Typen.
  Future<CalendarAllResponse> all({
    DateTime? start,
    DateTime? end,
    List<String>? types,
  }) async {
    final params = <String, String>{};
    if (start != null && end != null) {
      params['start'] = toApiDateOnly(start);
      params['end'] = toApiDateOnly(end);
    }
    if (types != null && types.isNotEmpty) {
      params['types'] = types.join(',');
    }

    final data = await _api.get(
      '/calendar/all',
      queryParams: params.isNotEmpty ? params : null,
      token: await _token(),
    );
    return CalendarAllResponse.fromJson(data);
  }

  Future<CalendarEvent> create({
    required String title,
    String? description,
    required bool allDay,
    required DateTime startDate,
    required DateTime endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int visibility = 0,
    List<String>? participantIds,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'allDay': allDay,
      'startDate': toApiDateOnly(startDate),
      'endDate': toApiDateOnly(endDate),
      'visibility': visibility,
    };
    if (!allDay && startTime != null && endTime != null) {
      body['startTime'] = toApiTime(startTime);
      body['endTime'] = toApiTime(endTime);
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

  /// Partielles Update. Beim Umschalten auf ganztägig werden `startTime`/
  /// `endTime` als `null` gesendet, damit die API die Uhrzeiten leert.
  Future<CalendarEvent> update(
    String id, {
    String? title,
    String? description,
    bool? allDay,
    DateTime? startDate,
    DateTime? endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? visibility,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (allDay != null) body['allDay'] = allDay;
    if (startDate != null) body['startDate'] = toApiDateOnly(startDate);
    if (endDate != null) body['endDate'] = toApiDateOnly(endDate);
    if (allDay == true) {
      body['startTime'] = null;
      body['endTime'] = null;
    } else {
      if (startTime != null) body['startTime'] = toApiTime(startTime);
      if (endTime != null) body['endTime'] = toApiTime(endTime);
    }
    if (visibility != null) body['visibility'] = visibility;

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
