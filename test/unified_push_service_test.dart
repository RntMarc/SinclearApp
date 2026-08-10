import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/features/notifications/services/unified_push_service.dart';

class MockApiClient extends ApiClient {
  MockApiClient() : super(baseUrl: 'http://localhost');
}

void main() {
  late UnifiedPushService service;
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
    service = UnifiedPushService(api: mockApi);
  });

  tearDown(() {
    service.dispose();
  });

  group('UnifiedPushService', () {
    test('constructor creates instance', () {
      expect(service, isNotNull);
    });
  });
}
