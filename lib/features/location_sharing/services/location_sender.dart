import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationSender {
  Timer? _timer;

  bool get isSharing => _timer != null;

  void start({
    required String sessionId,
    required int frequencySeconds,
    required Future<void> Function(String sessionId, Position position) onTick,
    required VoidCallback onComplete,
  }) {
    stop();

    if (kIsWeb) {
      _startWeb(frequencySeconds, sessionId, onTick);
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      _startMobile(frequencySeconds, sessionId, onTick, onComplete);
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _startMobile(frequencySeconds, sessionId, onTick, onComplete);
      return;
    }
  }

  void _startMobile(
    int frequencySeconds,
    String sessionId,
    Future<void> Function(String sessionId, Position position) onTick,
    VoidCallback onComplete,
  ) {
    _timer = Timer.periodic(Duration(seconds: frequencySeconds), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await onTick(sessionId, position);
      } catch (_) {}
    });

    Future.delayed(const Duration(seconds: 1), () async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await onTick(sessionId, position);
      } catch (_) {}
    });
  }

  void _startWeb(
    int frequencySeconds,
    String sessionId,
    Future<void> Function(String sessionId, Position position) onTick,
  ) {
    _timer = Timer.periodic(Duration(seconds: frequencySeconds), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await onTick(sessionId, position);
      } catch (_) {}
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
