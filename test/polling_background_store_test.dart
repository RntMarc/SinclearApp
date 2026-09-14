import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinclear_beyond/features/notifications/services/polling_background_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'lastSeen und foregroundActive werden persistiert und resettet',
    () async {
      final store = PollingBackgroundStore();

      expect(await store.lastSeen(), isNull);
      expect(await store.foregroundActive(), isFalse);

      await store.setLastSeen('2026-01-01 10:00:00.000');
      await store.setForegroundActive(true);
      expect(await store.lastSeen(), '2026-01-01 10:00:00.000');
      expect(await store.foregroundActive(), isTrue);

      await store.reset();
      expect(await store.lastSeen(), isNull);
      expect(await store.foregroundActive(), isFalse);
    },
  );

  test('foregroundAlive erfordert einen frischen Heartbeat', () async {
    final store = PollingBackgroundStore();

    expect(await store.foregroundAlive(), isFalse);

    await store.setForegroundActive(true);
    expect(await store.foregroundAlive(), isFalse);

    await store.touchHeartbeat();
    expect(await store.foregroundAlive(), isTrue);

    await store.touchHeartbeat(
      DateTime.now().subtract(const Duration(minutes: 20)),
    );
    expect(await store.foregroundAlive(), isFalse);
  });
}
