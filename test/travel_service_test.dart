import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';
import 'package:sinclear_beyond/features/travel/services/travel_service.dart';

class _CaptureApi extends ApiClient {
  final List<Map<String, dynamic>?> bodies = [];
  final List<String> paths = [];

  _CaptureApi() : super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    paths.add(path);
    bodies.add(body);
    return {
      'data': {
        'id': 't1',
        'name': body?['name'] ?? '',
        'hastickets': '0',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    paths.add(path);
    bodies.add(body);
    return {
      'data': {
        'id': 't1',
        'name': body?['name'] ?? '',
        'hastickets': '0',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
    bool parseResponse = false,
  }) async {
    paths.add(path);
    return {'ok': true};
  }
}

class _FakeAuth extends AuthService {
  _FakeAuth() : super(api: _CaptureApi(), storage: TokenStorage());

  @override
  Future<String> getAccessToken() async => 'test-token';
}

void main() {
  late _CaptureApi api;
  late TravelService service;

  setUp(() {
    api = _CaptureApi();
    service = TravelService(api: api, auth: _FakeAuth());
  });

  group('createTrip', () {
    test('ganztägig sendet startDate/endDate ohne Zeitfelder', () async {
      await service.createTrip(
        name: 'Italien',
        allDay: true,
        timezone: 'Europe/Berlin',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 5),
      );

      expect(api.paths.single, '/trips');
      final body = api.bodies.single!;
      expect(body['name'], 'Italien');
      expect(body['allDay'], true);
      expect(body['startDate'], '2026-09-01');
      expect(body['endDate'], '2026-09-05');
      expect(body.containsKey('startAt'), isFalse);
      expect(body.containsKey('endAt'), isFalse);
    });

    test('getaktet sendet startAt/endAt als RFC-3339 mit Offset', () async {
      await service.createTrip(
        name: 'Konferenz',
        allDay: false,
        timezone: 'UTC',
        startAt: DateTime(2026, 9, 1, 9),
        endAt: DateTime(2026, 9, 1, 17),
      );

      final body = api.bodies.single!;
      expect(body['allDay'], false);
      expect(body['startAt'], contains('T'));
      expect(body['endAt'], contains('T'));
      expect(body.containsKey('startDate'), isFalse);
    });

    test('hastickets wird zu 1/0 kodiert', () async {
      await service.createTrip(
        name: 'Reise',
        allDay: true,
        timezone: 'UTC',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 2),
        hastickets: true,
      );

      expect(api.bodies.single!['hastickets'], '1');
    });
  });

  group('deleteTrip', () {
    test('ruft DELETE /trips/{id} auf', () async {
      await service.deleteTrip('t1');
      expect(api.paths.single, '/trips/t1');
    });
  });

  group('addTripParticipant', () {
    test('sendet userId', () async {
      await service.addTripParticipant('t1', 'u1');
      expect(api.paths.single, '/trips/t1/participants');
      expect(api.bodies.single!['userId'], 'u1');
    });
  });
}
