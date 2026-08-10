import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/features/notifications/services/web_push_service.dart';

class MockApiClient extends ApiClient {
  MockApiClient() : super(baseUrl: 'http://localhost');
}

void main() {
  late WebPushService service;
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
    service = WebPushService(api: mockApi);
  });

  group('WebPushService', () {
    test('constructor creates instance', () {
      expect(service, isNotNull);
    });

    test('isSupported returns false in test environment', () {
      expect(service.isSupported, isFalse);
    });

    test('setup does not throw when not supported', () async {
      expect(
        () => service.setup(token: 'test-token'),
        returnsNormally,
      );
    });

    test('unsubscribe does not throw when not supported', () async {
      expect(
        () => service.unsubscribe(token: 'test-token'),
        returnsNormally,
      );
    });
  });
}
