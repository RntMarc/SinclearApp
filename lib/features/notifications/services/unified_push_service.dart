import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unifiedpush/unifiedpush.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_item.dart';

class UnifiedPushService extends ChangeNotifier {
  final ApiClient _api;
  String? _token;
  String? _savedEndpoint;

  bool _initialized = false;

  UnifiedPushService({required this._api});

  void init({
    required String token,
    void Function(NotificationItem item)? onMessage,
  }) {
    _token = token;
    if (_initialized) return;

    UnifiedPush.initialize(
      onNewEndpoint: (PushEndpoint endpoint, String instance) {
        _savedEndpoint = endpoint.url;
        _registerEndpoint(endpoint.url);
      },
      onRegistrationFailed: (FailedReason reason, String? instance) {
        developer.log('UnifiedPush registration failed: $reason', name: 'unifiedpush');
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
          onMessage?.call(item);
        } catch (e) {
          developer.log('Failed to parse UP message: $e', name: 'unifiedpush');
        }
      },
    );
    _initialized = true;
  }

  Future<void> checkAndSetup({
    required BuildContext context,
    required Future<void> Function(List<String> distributors)
    onDistributorsFound,
    required Future<void> Function() onNoDistributor,
  }) async {
    if (kIsWeb) return;

    final distributor = await UnifiedPush.getDistributor();
    if (distributor != null) {
      await UnifiedPush.register();
      return;
    }

    final distributors = await UnifiedPush.getDistributors();
    if (distributors.isNotEmpty) {
      await onDistributorsFound(distributors);
    } else {
      await onNoDistributor();
    }
  }

  Future<void> selectDistributor(String distributor) async {
    await UnifiedPush.saveDistributor(distributor);
    await UnifiedPush.register();
  }

  Future<void> _registerEndpoint(String endpoint) async {
    if (_token == null) return;

    try {
      await _api.post(
        '/notifications/push-subscription',
        body: {'type': 'unifiedpush', 'endpoint': endpoint},
        token: _token,
      );
    } catch (e) {
      developer.log('Failed to register UP endpoint: $e', name: 'unifiedpush');
    }
  }

  Future<void> _unregisterEndpoint(String endpoint) async {
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

  Future<void> unregister() async {
    await UnifiedPush.unregister();
    if (_savedEndpoint != null) {
      await _unregisterEndpoint(_savedEndpoint!);
      _savedEndpoint = null;
    }
  }
}
