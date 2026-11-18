import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'fcm_setup_result.dart';

/// Platzhalter für alle Plattformen ohne FCM (Web, Desktop).
///
/// FCM ist ausschließlich für natives Android gedacht; Web nutzt Web Push.
class FcmPushService extends ChangeNotifier {
  FcmPushService({required ApiClient api});

  Future<FcmSetupResult> setup({
    required Future<String> Function() getToken,
    required Future<void> Function() onWakeup,
  }) async => FcmSetupResult.unavailable;

  Future<void> unregister({String? token}) async {}
}
