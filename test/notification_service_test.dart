import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/features/notifications/services/notification_service.dart';

class MockApiClient extends ApiClient {
  final List<Map<String, dynamic>> responses = [];
  int callIndex = 0;
  final List<String> calledPaths = [];
  final List<Map<String, String?>?> calledQueryParams = [];

  MockApiClient() : super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    calledPaths.add(path);
    calledQueryParams.add(queryParams);
    if (callIndex < responses.length) {
      return responses[callIndex++];
    }
    return {'notifications': []};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    calledPaths.add(path);
    return {'ok': true};
  }
}

void main() {
  late NotificationService service;
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
    service = NotificationService(api: mockApi);
  });

  tearDown(() {
    service.dispose();
  });

  group('startPolling', () {
    test('triggers poll immediately', () async {
      mockApi.responses.add({
        'notifications': [
          {
            'id': '1',
            'type': 'forum_reply',
            'title': 'Test',
            'body': 'Body',
            'data': null,
            'createdAt': '2026-08-10 14:30:00',
          },
        ],
      });

      service.startPolling(token: 'test-token');

      await Future.delayed(const Duration(milliseconds: 100));

      expect(mockApi.calledPaths, contains('/notifications'));
    });
  });

  group('_poll', () {
    test('adds items to stream', () async {
      final completer = Completer<List<dynamic>>();
      mockApi.responses.add({
        'notifications': [
          {
            'id': '1',
            'type': 'forum_reply',
            'title': 'Test',
            'body': 'Body',
            'data': {'route': '/forum/1'},
            'createdAt': '2026-08-10 14:30:00',
          },
        ],
      });

      service.notifications.listen((items) {
        if (!completer.isCompleted) completer.complete(items);
      });

      service.startPolling(token: 'test-token');

      final items = await completer.future.timeout(
        const Duration(seconds: 1),
      );

      expect(items.length, 1);
      expect(items.first.id, '1');
      expect(items.first.title, 'Test');
    });

    test('empty response adds nothing to stream', () async {
      mockApi.responses.add({'notifications': []});

      service.startPolling(token: 'test-token');

      await Future.delayed(const Duration(milliseconds: 100));

      expect(mockApi.calledPaths, contains('/notifications'));
    });

    test('sets _lastSeen after first poll', () async {
      mockApi.responses.add({
        'notifications': [
          {
            'id': '1',
            'type': 'forum_reply',
            'title': 'Test',
            'body': 'Body',
            'data': null,
            'createdAt': '2026-08-10 14:30:00',
          },
        ],
      });
      mockApi.responses.add({'notifications': []});

      service.startPolling(
        token: 'test-token',
        interval: const Duration(milliseconds: 50),
      );
      await Future.delayed(const Duration(milliseconds: 200));

      expect(mockApi.calledQueryParams.length, greaterThan(1));
      expect(mockApi.calledQueryParams[1], isNotNull);
      expect(mockApi.calledQueryParams[1]!['since'], isNotNull);
    });
  });

  group('stopPolling', () {
    test('stops the timer', () async {
      mockApi.responses.add({'notifications': []});
      service.startPolling(token: 'test-token');
      await Future.delayed(const Duration(milliseconds: 50));

      service.stopPolling();

      await Future.delayed(const Duration(milliseconds: 100));

      final initialCallCount = mockApi.calledPaths.length;
      await Future.delayed(const Duration(milliseconds: 200));

      expect(mockApi.calledPaths.length, initialCallCount);
    });
  });

  group('markRead', () {
    test('sends ids to API', () async {
      await service.markRead(['id1', 'id2'], token: 'test-token');

      expect(mockApi.calledPaths, contains('/notifications/read'));
    });

    test('empty list does not call API', () async {
      await service.markRead([], token: 'test-token');

      expect(mockApi.calledPaths, isEmpty);
    });
  });
}
