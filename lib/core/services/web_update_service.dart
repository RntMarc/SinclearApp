import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_update_service_stub.dart'
    if (dart.library.html) 'web_update_service_web.dart'
    as platform;

class WebUpdateService {
  static const _buildNumberKey = 'web_known_build_number';
  static const _pollInterval = Duration(minutes: 5);

  Timer? _timer;

  Future<void> init() async {
    await _checkForUpdate();
    _timer = Timer.periodic(_pollInterval, (_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    try {
      final serverBuildNumber = await platform.fetchServerBuildNumber();
      if (serverBuildNumber == null) return;

      final prefs = await SharedPreferences.getInstance();
      final localBuildNumber = prefs.getString(_buildNumberKey);

      if (localBuildNumber == null) {
        await prefs.setString(_buildNumberKey, serverBuildNumber);
        return;
      }

      if (serverBuildNumber != localBuildNumber) {
        await prefs.setString(_buildNumberKey, serverBuildNumber);
        platform.reloadPage();
      }
    } catch (_) {
      // Silently ignore – update check should never crash the app
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
