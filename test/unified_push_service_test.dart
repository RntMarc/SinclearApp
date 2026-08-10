import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/features/notifications/services/notification_service.dart';
import 'package:sinclear_beyond/features/notifications/services/unified_push_service.dart';

class MockApiClient extends ApiClient {
  MockApiClient() : super(baseUrl: 'http://localhost');
}

void main() {
  late UnifiedPushService service;
  late MockApiClient mockApi;
  late NotificationService notificationService;

  setUp(() {
    mockApi = MockApiClient();
    notificationService = NotificationService(api: mockApi);
    service = UnifiedPushService(
      api: mockApi,
      notificationService: notificationService,
    );
  });

  tearDown(() {
    notificationService.dispose();
    service.dispose();
  });

  group('UnifiedPushService', () {
    test('constructor creates instance', () {
      expect(service, isNotNull);
    });
  });
}
