import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/services/auth_service.dart';
import '../models/calendar_models.dart';

class CalendarService {
  final ApiClient _api;
  final AuthService _auth;

  CalendarService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

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
      params['start'] = toApiDate(start);
      params['end'] = toApiDate(end);
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

  Future<CalendarEvent> create({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    int visibility = 0,
    List<String>? participantIds,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'startTime': toApiDate(startTime),
      'endTime': toApiDate(endTime),
      'visibility': visibility,
    };
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

  Future<CalendarEvent> update(
    String id, {
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    int? visibility,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (startTime != null) {
      body['startTime'] = toApiDate(startTime);
    }
    if (endTime != null) {
      body['endTime'] = toApiDate(endTime);
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
