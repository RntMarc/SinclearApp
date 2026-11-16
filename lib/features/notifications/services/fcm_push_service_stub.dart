import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';

/// Platzhalter für alle Plattformen ohne FCM (Web, Desktop).
///
/// FCM ist ausschließlich für natives Android gedacht; Web nutzt Web Push.
/// Durch den bedingten Export in `fcm_push_service.dart` werden die
/// Firebase-Pakete gar nicht erst in andere Builds gezogen.
class FcmPushService extends ChangeNotifier {
  FcmPushService({required ApiClient api});

  Future<bool> setup({
    required Future<String> Function() getToken,
    required Future<void> Function() onWakeup,
  }) async => false;

  Future<void> unregister({String? token}) async {}
}
