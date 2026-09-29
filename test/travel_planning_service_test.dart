import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';
import 'package:sinclear_beyond/features/travel/services/travel_planning_service.dart';

/// Erfasst Pfade/Bodies und liefert pro Endpunkt eine minimale, gültige
/// Antwort, damit die Modelle geparst werden können.
class _CaptureApi extends ApiClient {
  final List<String> paths = [];
  final List<Map<String, dynamic>?> bodies = [];

  _CaptureApi() : super(baseUrl: 'http://localhost');

  Map<String, dynamic> _resource() {
    final path = paths.last;
    if (path.endsWith('/dates') || path.contains('/dates/')) {
      return {
        'data': {'id': 'd1', 'tripId': 'p1'},
      };
    }
    if (path.contains('/accommodations')) {
      return {
        'data': {'id': 'a1', 'tripId': 'p1', 'name': 'Hotel'},
      };
    }
    if (path.endsWith('/events') || path.contains('/events/')) {
      return {
        'data': {'id': 'e1', 'tripId': 'p1', 'name': 'Museum'},
      };
    }
    if (path.endsWith('/transport')) {
      return {
        'data': {'id': 'tr1', 'tripId': 'p1', 'userId': 'u1'},
      };
    }
    return {
      'data': {'id': 'p1', 'name': 'Reise', 'state': 'planning'},
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    paths.add(path);
    bodies.add(body);
    if (path.endsWith('/members')) {
      return {
        'data': {'id': 'm1'},
      };
    }
    return _resource();
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    paths.add(path);
    if (path == '/trips/planning') {
      return {'data': []};
    }
    if (path.endsWith('/dates') ||
        path.endsWith('/members') ||
        path.endsWith('/transport') ||
        path.endsWith('/events') ||
        path.endsWith('/accommodations')) {
      return {'data': []};
    }
    return _resource();
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    paths.add(path);
    bodies.add(body);
    return _resource();
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    paths.add(path);
    bodies.add(body);
    if (path.contains('/topics/')) return {'data': []};
    return _resource();
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
    bool parseResponse = false,
  }) async {
    paths.add(path);
    return {};
  }
}

class _FakeAuth extends AuthService {
  _FakeAuth() : super(api: _CaptureApi(), storage: TokenStorage());

  @override
  Future<String> getAccessToken() async => 'test-token';
}

void main() {
  late _CaptureApi api;
  late TravelPlanningService service;

  setUp(() {
    api = _CaptureApi();
    service = TravelPlanningService(api: api, auth: _FakeAuth());
  });

  test('list ruft GET /trips/planning paginiert auf', () async {
    await service.list();
    expect(api.paths.single, '/trips/planning');
  });

  test('create sendet name/description/skippedTopics', () async {
    await service.create(
      name: 'Sommer',
      description: 'Beschreibung',
      skippedTopics: ['program'],
    );
    expect(api.paths.single, '/trips/planning');
    final body = api.bodies.single!;
    expect(body['name'], 'Sommer');
    expect(body['description'], 'Beschreibung');
    expect(body['skippedTopics'], ['program']);
  });

  test('create ohne skippedTopics sendet keinen Schlüssel', () async {
    await service.create(name: 'Sommer');
    expect(api.bodies.single!.containsKey('skippedTopics'), isFalse);
  });

  test('getDetail ruft GET /trips/planning/{id} auf', () async {
    await service.getDetail('p1');
    expect(api.paths.single, '/trips/planning/p1');
  });

  test('update sendet nur gesetzte Felder per PATCH', () async {
    await service.update('p1', name: 'Neu');
    expect(api.paths.single, '/trips/planning/p1');
    expect(api.bodies.single!['name'], 'Neu');
    expect(api.bodies.single!.containsKey('description'), isFalse);
  });

  test('activate ruft POST /trips/planning/{id}/activate auf', () async {
    await service.activate('p1');
    expect(api.paths.single, '/trips/planning/p1/activate');
  });

  test('inviteMember sendet userId', () async {
    await service.inviteMember('p1', 'u2');
    expect(api.paths.single, '/trips/planning/p1/members');
    expect(api.bodies.single!['userId'], 'u2');
  });

  test('respond sendet response per PUT members/me', () async {
    await service.respond('p1', 'accepted');
    expect(api.paths.single, '/trips/planning/p1/members/me');
    expect(api.bodies.single!['response'], 'accepted');
  });

  test('setMemberStatus sendet status per PATCH', () async {
    await service.setMemberStatus('p1', 'u2', 'inactive');
    expect(api.paths.single, '/trips/planning/p1/members/u2');
    expect(api.bodies.single!['status'], 'inactive');
  });

  test('removeMember ruft DELETE auf', () async {
    await service.removeMember('p1', 'u2');
    expect(api.paths.single, '/trips/planning/p1/members/u2');
  });

  test('setTopicStatus sendet status per PATCH topics/{topic}', () async {
    await service.setTopicStatus('p1', 'participants', 'completed');
    expect(api.paths.single, '/trips/planning/p1/topics/participants');
    expect(api.bodies.single!['status'], 'completed');
  });

  test('createDateOption sendet ganztägige zivile Tage', () async {
    await service.createDateOption(
      'p1',
      label: 'Woche 1',
      allDay: true,
      timezone: 'Europe/Berlin',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 5),
    );
    expect(api.paths.single, '/trips/planning/p1/dates');
    final body = api.bodies.single!;
    expect(body['label'], 'Woche 1');
    expect(body['allDay'], true);
    expect(body['startDate'], '2026-09-01');
    expect(body['endDate'], '2026-09-05');
  });

  test('setDateResponse sendet availability', () async {
    await service.setDateResponse('p1', 'd1', 'maybe');
    expect(api.paths.single, '/trips/planning/p1/dates/d1/responses');
    expect(api.bodies.single!['availability'], 'maybe');
  });

  test('finalizeDate ruft finalize auf', () async {
    await service.finalizeDate('p1', 'd1');
    expect(api.paths.single, '/trips/planning/p1/dates/d1/finalize');
  });

  test('setTransport sendet direction/mode/offersRide per PUT', () async {
    await service.setTransport(
      'p1',
      direction: 'return',
      mode: 'Zug',
      offersRide: true,
      availableSeats: 2,
    );
    expect(api.paths.single, '/trips/planning/p1/transport');
    final body = api.bodies.single!;
    expect(body['direction'], 'return');
    expect(body['mode'], 'Zug');
    expect(body['offersRide'], true);
    expect(body['availableSeats'], 2);
  });

  test('createAccommodationOption sendet name und Preis', () async {
    await service.createAccommodationOption(
      'p1',
      name: 'Hotel',
      pricePerPersonPerNight: 42.5,
      currency: 'EUR',
    );
    expect(api.paths.single, '/trips/planning/p1/accommodations');
    final body = api.bodies.single!;
    expect(body['name'], 'Hotel');
    expect(body['pricePerPersonPerNight'], 42.5);
    expect(body['currency'], 'EUR');
  });

  test('selectAccommodation ruft select auf', () async {
    await service.selectAccommodation('p1', 'a1');
    expect(api.paths.single, '/trips/planning/p1/accommodations/a1/select');
  });

  test('createEventSuggestion sendet name/dayIndex/allDay', () async {
    await service.createEventSuggestion(
      'p1',
      name: 'Museum',
      dayIndex: 1,
      allDay: false,
      timezone: 'Europe/Berlin',
      startAt: DateTime(2026, 9, 1, 10),
      endAt: DateTime(2026, 9, 1, 12),
    );
    expect(api.paths.single, '/trips/planning/p1/events');
    final body = api.bodies.single!;
    expect(body['name'], 'Museum');
    expect(body['dayIndex'], 1);
    expect(body['allDay'], false);
    expect(body['startAt'], contains('T'));
    expect(body.containsKey('startDate'), isFalse);
  });

  test('setEventInterest sendet interest', () async {
    await service.setEventInterest('p1', 'e1', 'yes');
    expect(api.paths.single, '/trips/planning/p1/events/e1/interest');
    expect(api.bodies.single!['interest'], 'yes');
  });

  test('confirmEvent sendet confirmed', () async {
    await service.confirmEvent('p1', 'e1', confirmed: false);
    expect(api.paths.single, '/trips/planning/p1/events/e1/confirm');
    expect(api.bodies.single!['confirmed'], false);
  });
}
