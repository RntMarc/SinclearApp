import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/notifications/notification_lifecycle_observer.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/features/notifications/services/notification_service.dart';
import 'package:sinclear_beyond/features/settings/models/notification_preference.dart';

class MockApiClient extends ApiClient {
  MockApiClient() : super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    return {'notifications': []};
  }
}

void main() {
  testWidgets('NotificationLifecycleObserver is created and can be disposed', (
    tester,
  ) async {
    final mockApi = MockApiClient();
    final notificationService = NotificationService(api: mockApi);

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationLifecycleObserver(
          notificationService: notificationService,
          getToken: () async => 'test-token',
          getNotificationMethod: () => NotificationMethod.polling,
          child: const Scaffold(body: Text('Test')),
        ),
      ),
    );

    expect(find.text('Test'), findsOneWidget);

    notificationService.dispose();
  });
}
