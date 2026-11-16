import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_item.dart';
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

  test('markAsShown und filterAndMarkNew deduplizieren persistent', () async {
    final store = PollingBackgroundStore();
    final item = NotificationItem(
      id: 'notif-1',
      type: 'story_post',
      title: 'Neue Story',
      text: 'James hat eine neue Story veröffentlicht.',
      createdAt: DateTime.utc(2026, 8, 10, 14, 30, 0, 123),
    );

    expect(await store.wasShown(item), isFalse);
    expect(await store.markAsShown(item), isTrue);
    expect(await store.wasShown(item), isTrue);
    expect(await store.markAsShown(item), isFalse);

    // Ein zweites Isolate / neuer Store erkennt das bereits gezeigte Item.
    final secondStore = PollingBackgroundStore();
    final fresh = await secondStore.filterAndMarkNew([item]);
    expect(fresh, isEmpty);

    // Coalesced Upsert (gleiche ID, neuerer createdAt) gilt als neue Nachricht.
    final updatedItem = NotificationItem(
      id: 'notif-1',
      type: 'direct_message',
      title: 'Neue Nachricht',
      text: 'James: Zweite Nachricht',
      createdAt: DateTime.utc(2026, 8, 10, 14, 35, 0, 456),
    );
    final freshUpdated = await secondStore.filterAndMarkNew([updatedItem]);
    expect(freshUpdated, hasLength(1));
  });
}
