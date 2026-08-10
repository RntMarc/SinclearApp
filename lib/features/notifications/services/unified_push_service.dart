import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unifiedpush/unifiedpush.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_item.dart';
import 'notification_service.dart';

class UnifiedPushService extends ChangeNotifier {
  final ApiClient _api;
  final NotificationService _notificationService;
  String? _token;
  String? _savedEndpoint;

  UnifiedPushService({
    required this._api,
    required this._notificationService,
  });

  void init({
    required String token,
    void Function(NotificationItem item)? onMessage,
  }) {
    _token = token;

    UnifiedPush.initialize(
      onNewEndpoint: (endpoint, instance) {
        _savedEndpoint = endpoint;
        _registerEndpoint(endpoint);
      },
      onRegistrationFailed: (instance) {
        developer.log(
          'UnifiedPush registration failed',
          name: 'unifiedpush',
        );
      },
      onUnregistered: (instance) {
        if (_savedEndpoint != null) {
          _unregisterEndpoint(_savedEndpoint!);
          _savedEndpoint = null;
        }
      },
      onMessage: (Uint8List message, String instance) {
        try {
          final json = jsonDecode(String.fromCharCodes(message));
          final item = NotificationItem.fromJson(
            json as Map<String, dynamic>,
          );
          onMessage?.call(item);
        } catch (e) {
          developer.log(
            'Failed to parse UP message: $e',
            name: 'unifiedpush',
          );
        }
      },
    );
  }

  Future<void> checkAndSetup({
    required BuildContext context,
    required void Function(List<String> distributors) onDistributorsFound,
    required void Function() onNoDistributor,
  }) async {
    if (kIsWeb) return;

    final distributor = await UnifiedPush.getDistributor();
    if (distributor != null) {
      await UnifiedPush.registerApp();
      return;
    }

    final distributors = await UnifiedPush.getDistributors();
    if (distributors.isNotEmpty) {
      onDistributorsFound(distributors);
    } else {
      onNoDistributor();
    }
  }

  Future<void> selectDistributor(String distributor) async {
    await UnifiedPush.saveDistributor(distributor);
    await UnifiedPush.registerApp();
  }

  Future<void> _registerEndpoint(String endpoint) async {
    if (_token == null) return;

    try {
      await _api.post(
        '/notifications/push-subscription',
        body: {
          'type': 'unifiedpush',
          'endpoint': endpoint,
        },
        token: _token,
      );
    } catch (e) {
      developer.log(
        'Failed to register UP endpoint: $e',
        name: 'unifiedpush',
      );
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
