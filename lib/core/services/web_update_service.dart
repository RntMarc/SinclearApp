import 'dart:async';

import 'package:flutter/foundation.dart';

import 'web_update_service_stub.dart'
    if (dart.library.html) 'web_update_service_web.dart'
    as platform;

/// Checks for web builds that are newer than the currently running build.
class WebUpdateService {
  static const _pollInterval = Duration(minutes: 5);

  /// Creates a service that compares remote metadata with [currentBuildNumber].
  WebUpdateService({required this.currentBuildNumber});

  /// Build number compiled into the currently running app session.
  final String currentBuildNumber;

  /// Emits `true` when the root `version.json` describes a newer build.
  final ValueNotifier<bool> updateAvailable = ValueNotifier(false);

  /// Human-readable version from the root `version.json`, shown in the banner.
  String? latestVersion;

  Timer? _timer;

  /// Starts periodic checks without applying an update automatically.
  Future<void> init() async {
    await _checkForUpdate();
    _timer = Timer.periodic(_pollInterval, (_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    try {
      final rootVersion = await platform.fetchRootVersion();
      if (rootVersion == null) return;

      if (rootVersion.buildNumber == currentBuildNumber) return;

      latestVersion = rootVersion.version;
      updateAvailable.value = true;
    } catch (_) {
      // Silently ignore; update checks must never interrupt the app session.
    }
  }

  /// Reloads the current page only after the user explicitly requests it.
  void reload() {
    platform.reloadPage();
  }

  /// Hides the banner for the current app session.
  void dismiss() {
    updateAvailable.value = false;
  }

  /// Stops update polling and releases listeners.
  void dispose() {
    _timer?.cancel();
    updateAvailable.dispose();
  }
}
