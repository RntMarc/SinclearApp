import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/notifications/services/background_poller.dart';
import 'package:sinclear_beyond/features/notifications/services/polling_background_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stableNotificationId ist deterministisch und positiv', () {
    final a = stableNotificationId('abc-123');
    expect(a, stableNotificationId('abc-123'));
    expect(a, isNot(stableNotificationId('abc-124')));
    expect(a, greaterThanOrEqualTo(0));
  });

  test(
    'Poll schreibt den Cursor fort und nutzt since beim nächsten Lauf',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = TokenStorage();
      await storage.saveRefreshToken('refresh-1', 0);
      final store = PollingBackgroundStore();

      final notificationRequests = <Uri>[];
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          return http.Response(
            jsonEncode({
              'access_token': 'access-1',
              'refresh_token': 'refresh-2',
              'expires_in': 3600,
              'expires_at': 0,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        notificationRequests.add(request.url);
        return http.Response(
          jsonEncode({
            'notifications': [
              {
                'id': 'n1',
                'type': 'forum_reply',
                'title': 'Titel',
                'text': 'Text',
                'data': <Map<String, dynamic>>[],
                'isRead': false,
                'createdAt': '2026-01-01 10:00:00',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final api = ApiClient(baseUrl: 'http://test', client: client);
      await runHeadlessPoll(api: api, storage: storage, store: store);

      final cursor = await store.lastSeen();
      expect(cursor, isNotNull);
      expect(notificationRequests.single.queryParameters['since'], isNull);

      await runHeadlessPoll(api: api, storage: storage, store: store);
      expect(notificationRequests.length, 2);
      expect(notificationRequests.last.queryParameters['since'], cursor);

      // Der aufgefrischte Refresh-Token wird persistiert.
      expect(await storage.getRefreshToken(), 'refresh-2');
    },
  );
}
