import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unifiedpush/unifiedpush.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_item.dart';

class UnifiedPushService extends ChangeNotifier {
  static const _savedEndpointKey = 'unifiedpush_saved_endpoint';

  final ApiClient _api;
  String? _token;
  String? _savedEndpoint;
  void Function(NotificationItem item)? _onMessage;

  bool _initialized = false;

  /// Wartet auf den Endpoint der laufenden Registrierung. `null`, wenn keine
  /// Registrierung angefordert wurde (z. B. Endpoint-Rotation im Betrieb).
  Completer<bool>? _registration;

  UnifiedPushService({required this._api});

  Future<void> init({
    required String token,
    void Function(NotificationItem item)? onMessage,
  }) async {
    _token = token;
    if (onMessage != null) {
      _onMessage = onMessage;
    }
    if (_initialized) return;

    await UnifiedPush.initialize(
      onNewEndpoint: (PushEndpoint endpoint, String instance) async {
        final registered = await _registerEndpoint(endpoint.url);
        _finishRegistration(registered);
      },
      onRegistrationFailed: (FailedReason reason, String? instance) {
        developer.log(
          'UnifiedPush registration failed: $reason',
          name: 'unifiedpush',
        );
        _finishRegistration(false);
      },
      onUnregistered: (String instance) {
        if (_savedEndpoint != null) {
          _unregisterEndpoint(_savedEndpoint!);
          _savedEndpoint = null;
        }
      },
      onMessage: (PushMessage message, String instance) {
        try {
          final json = jsonDecode(utf8.decode(message.content));
          final item = NotificationItem.fromJson(json as Map<String, dynamic>);
          _onMessage?.call(item);
        } catch (e) {
          developer.log('Failed to parse UP message: $e', name: 'unifiedpush');
        }
      },
    );
    _initialized = true;
  }

  /// Der aktuell eingerichtete Distributor, oder `null`.
  Future<String?> registeredDistributor() {
    if (kIsWeb) return Future.value(null);
    return UnifiedPush.getDistributor();
  }

  /// Installierte UnifiedPush-Distributoren.
  Future<List<String>> availableDistributors() {
    if (kIsWeb) return Future.value(const []);
    return UnifiedPush.getDistributors();
  }

  /// Registriert die App beim aktuell eingerichteten Distributor und wartet
  /// auf den neuen Endpoint inklusive erfolgreicher API-Registrierung.
  ///
  /// Liefert nur `true`, wenn der Endpoint wirklich beim Sinclear-Server
  /// hinterlegt wurde — ein Distributor allein reicht nicht.
  Future<bool> register() async {
    if (kIsWeb) return false;

    final completer = Completer<bool>();
    _registration = completer;
    try {
      await UnifiedPush.register();
    } catch (e) {
      developer.log(
        'Failed to register with distributor: $e',
        name: 'unifiedpush',
      );
      _finishRegistration(false);
      return false;
    }

    return completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () async {
        if (identical(_registration, completer)) _registration = null;
        // Manche Distributoren melden einen bereits bekannten Endpoint nicht
        // erneut. Dann den gespeicherten Endpoint direkt (erneut) registrieren
        // und so auch `lastSeenAt` serverseitig auffrischen.
        final endpoint = await _savedEndpointOrNull();
        if (endpoint == null || endpoint.isEmpty) {
          developer.log(
            'UnifiedPush registration timed out',
            name: 'unifiedpush',
          );
          return false;
        }
        return _registerEndpoint(endpoint);
      },
    );
  }

  /// Speichert [distributor] und registriert ihn; `false` bei Fehlschlag.
  Future<bool> selectDistributor(String distributor) async {
    await UnifiedPush.saveDistributor(distributor);
    return register();
  }

  void _finishRegistration(bool success) {
    final completer = _registration;
    if (completer == null || completer.isCompleted) return;
    _registration = null;
    completer.complete(success);
  }

  Future<String?> _savedEndpointOrNull() async {
    if (_savedEndpoint != null) return _savedEndpoint;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_savedEndpointKey);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _registerEndpoint(String endpoint) async {
    _savedEndpoint = endpoint;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedEndpointKey, endpoint);
    } catch (_) {}

    if (_token == null) return false;

    try {
      await _api.post(
        '/notifications/push-subscription',
        body: {'type': 'unifiedpush', 'endpoint': endpoint},
        token: _token,
      );
      return true;
    } catch (e) {
      developer.log('Failed to register UP endpoint: $e', name: 'unifiedpush');
      return false;
    }
  }

  Future<void> _unregisterEndpoint(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedEndpointKey);
    } catch (_) {}

    if (_token == null) return;

    try {
      await _api.delete(
        '/notifications/push-subscription',
        body: {'endpoint': endpoint},
        token: _token,
      );
    } catch (e) {
      developer.log(
        'Failed to unregister UP endpoint: $e',
        name: 'unifiedpush',
      );
    }
  }

  Future<void> unregister({String? token}) async {
    _finishRegistration(false);
    if (token != null) _token = token;
    try {
      await UnifiedPush.unregister();
    } catch (e) {
      developer.log(
        'Failed to unregister from distributor: $e',
        name: 'unifiedpush',
      );
    }
    var endpoint = _savedEndpoint;
    if (endpoint == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        endpoint = prefs.getString(_savedEndpointKey);
      } catch (_) {}
    }
    if (endpoint != null && endpoint.isNotEmpty) {
      await _unregisterEndpoint(endpoint);
      _savedEndpoint = null;
    }
  }
}
