import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/local_notification_helper.dart';
import '../models/notification_item.dart';

class NotificationService extends ChangeNotifier {
  final ApiClient _api;

  Timer? _pollingTimer;
  String? _lastSeen;
  final StreamController<List<NotificationItem>> _controller =
      StreamController<List<NotificationItem>>.broadcast();

  Stream<List<NotificationItem>> get notifications => _controller.stream;

  NotificationService({required this._api});

  void startPolling({
    required String token,
    Duration interval = const Duration(seconds: 60),
  }) {
    stopPolling();
    _poll(token);
    _pollingTimer = Timer.periodic(interval, (_) => _poll(token));
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _poll(String token) async {
    try {
      final queryParams = <String, String>{};
      if (_lastSeen != null) {
        queryParams['since'] = _lastSeen!;
      }

      final response = await _api.get(
        '/notifications',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        token: token,
      );

      final notificationsList = response['notifications'] as List? ?? [];
      final items = notificationsList
          .map((json) => NotificationItem.fromJson(json as Map<String, dynamic>))
          .toList();

      if (items.isNotEmpty) {
        _lastSeen = items.first.createdAt.toIso8601String();
        _controller.add(items);
        notifyListeners();

        if (!kIsWeb) {
          final toShow = items.take(3).toList();
          for (final item in toShow) {
            final payload = item.data != null ? jsonEncode(item.data) : null;
            await LocalNotificationHelper.show(
              id: item.id.hashCode,
              title: item.title,
              body: item.body,
              payload: payload,
            );
          }
        }
      }
    } catch (e) {
      developer.log('Poll error: $e', name: 'notification_service');
    }
  }

  Future<void> markRead(List<String> ids, {required String token}) async {
    if (ids.isEmpty) return;
    try {
      await _api.post(
        '/notifications/read',
        body: {'ids': ids},
        token: token,
      );
    } catch (e) {
      developer.log('markRead error: $e', name: 'notification_service');
    }
  }

  @override
  void dispose() {
    stopPolling();
    _controller.close();
    super.dispose();
  }
}
