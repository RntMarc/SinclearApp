import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/date_utils.dart';
import '../models/location_sharing_models.dart';
import 'location_sender.dart';
import 'location_sharing_service.dart';

class LocationSharingManager extends ChangeNotifier {
  final LocationSharingService _service;
  final LocationSender _sender;

  LocationSharingManager({
    required LocationSharingService service,
    LocationSender? sender,
  })  : _service = service,
        _sender = sender ?? LocationSender();

  List<LocationSharingSessionDetail> _mySessions = [];
  List<LocationSharingSessionDetail> get mySessions => _mySessions;

  List<LocationSharingActiveSession> _contactSessions = [];
  List<LocationSharingActiveSession> get contactSessions => _contactSessions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Timer? _contactPollTimer;
  Timer? _localExpiryTimer;
  Set<String> _activeSenderSessions = {};

  bool get isSharing => _activeSenderSessions.isNotEmpty;

  @override
  void dispose() {
    _contactPollTimer?.cancel();
    _localExpiryTimer?.cancel();
    _sender.stop();
    super.dispose();
  }

  Future<void> loadMySessions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final sessions = await _service.getMySessions();
      final details = await Future.wait(
        sessions.map((s) => _service.getSessionDetail(s.id)),
      );
      _mySessions = details.where((d) => d.isActive).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadContactSessions() async {
    try {
      _contactSessions = await _service.getActiveFromContacts();
      notifyListeners();
    } catch (_) {}
  }

  Future<LocationSharingSessionDetail?> createSession({
    required List<String> recipientIds,
    required int durationSeconds,
    int frequencySeconds = 600,
    String sharingMode = 'location',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final req = CreateSessionRequest(
        recipientIds: recipientIds,
        durationSeconds: durationSeconds,
        frequencySeconds: frequencySeconds,
        sharingMode: sharingMode,
      );
      final session = await _service.createSession(req);
      _mySessions.add(session);
      _isLoading = false;
      notifyListeners();
      return session;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> extendSession(String id, int additionalSeconds) async {
    try {
      final current = _mySessions.where((s) => s.id == id).firstOrNull;
      if (current == null) return;

      final newDuration = current.durationSeconds + additionalSeconds;
      final updated = await _service.updateSession(
        id,
        UpdateSessionRequest(durationSeconds: newDuration),
      );
      _mySessions = _mySessions.map((s) => s.id == id ? updated : s).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopSession(String id) async {
    try {
      await _service.endSession(id);
      _mySessions = _mySessions.where((s) => s.id != id).toList();
      _stopSending(id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Map<String, LocationSharingLocation>> getLatestLocations(
    Set<String> sessionIds,
  ) async {
    final result = <String, LocationSharingLocation>{};
    for (final id in sessionIds) {
      try {
        final locations = await _service.getLocations(id);
        if (locations.isNotEmpty) {
          result[id] = locations.last;
        }
      } catch (_) {}
    }
    return result;
  }

  void startSending(LocationSharingSessionDetail session) {
    _activeSenderSessions.add(session.id);

    final expiresAt = parseApiDate(session.expiresAt);
    if (expiresAt != null) {
      final remaining = expiresAt.difference(DateTime.now());
      if (remaining.isNegative) return;

      _localExpiryTimer?.cancel();
      _localExpiryTimer = Timer(remaining, () {
        _mySessions = _mySessions.where((s) => s.id != session.id).toList();
        _activeSenderSessions.remove(session.id);
        if (_activeSenderSessions.isEmpty) {
          _sender.stop();
        }
        notifyListeners();
      });
    }

    _sender.start(
      sessionId: session.id,
      frequencySeconds: session.frequencySeconds,
      onTick: _sendLocation,
      onComplete: () {},
    );
  }

  void _stopSending(String sessionId) {
    _activeSenderSessions.remove(sessionId);
    if (_activeSenderSessions.isEmpty) {
      _sender.stop();
    }
  }

  Future<void> _sendLocation(String sessionId, Position position) async {
    try {
      await _service.sendLocation(
        sessionId,
        SendLocationRequest(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          recordedAt: toApiDate(DateTime.now()),
        ),
      );
    } catch (_) {}
  }

  void startContactPolling() {
    _contactPollTimer?.cancel();
    loadContactSessions();
    _contactPollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadContactSessions(),
    );
  }

  void stopContactPolling() {
    _contactPollTimer?.cancel();
    _contactPollTimer = null;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
