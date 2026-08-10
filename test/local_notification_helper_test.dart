import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/notifications/local_notification_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalNotificationHelper', () {
    test('show does not throw on web', () async {
      expect(
        () => LocalNotificationHelper.show(
          id: 1,
          title: 'Test',
          body: 'Body',
        ),
        returnsNormally,
      );
    });

    test('setNotificationTapHandler does not throw on web', () {
      expect(
        () => LocalNotificationHelper.setNotificationTapHandler((_) {}),
        returnsNormally,
      );
    });
  });
}
