import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/local_notification_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../models/notification_item.dart';

/// Stabile, nicht-negative Android-Notification-ID, abgeleitet aus der
/// Notification-UUID (Android akzeptiert nur ints >= 0).
int localNotificationId(String id) => id.hashCode & 0x7fffffff;

class NotificationService extends ChangeNotifier {
  final ApiClient _api;

  Timer? _pollingTimer;
  String? _lastSeen;

  /// IDs aller bereits angezeigten Benachrichtigungen dieser Session.
  /// Bewusst nicht bei `startPolling`/`stopPolling` zurückgesetzt, damit
  /// Resume/Cold-Start-Restarts keine Duplikate anzeigen.
  final Set<String> _seenIds = {};

  final StreamController<List<NotificationItem>> _controller =
      StreamController<List<NotificationItem>>.broadcast();

  Stream<List<NotificationItem>> get notifications => _controller.stream;

  NotificationService({required this._api});

  void startPolling({
    required String token,
    Duration interval = const Duration(seconds: 60),
  }) {
    if (_pollingTimer != null && _lastSeen != null) return;
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
          .map(
            (json) => NotificationItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      if (items.isNotEmpty) {
        _lastSeen = toApiDate(items.first.createdAt, withMilliseconds: true);
        final newItems = items.where((item) => _seenIds.add(item.id)).toList();
        if (newItems.isEmpty) return;
        _controller.add(newItems);
        notifyListeners();

        if (!kIsWeb) {
          final toShow = newItems.take(3).toList();
          for (final item in toShow) {
            await LocalNotificationHelper.show(
              id: localNotificationId(item.id),
              title: item.title,
              body: item.body,
              payload: jsonEncode({
                'id': item.id,
                'type': item.type,
                'data': item.data,
              }),
            );
          }
        }
      }
    } catch (e, st) {
      developer.log(
        'Poll error',
        error: e,
        stackTrace: st,
        name: 'notification_service',
      );
    }
  }

  Future<void> markRead(List<String> ids, {required String token}) async {
    if (ids.isEmpty) return;
    try {
      await _api.post('/notifications/read', body: {'ids': ids}, token: token);
    } catch (e, st) {
      developer.log(
        'markRead error',
        error: e,
        stackTrace: st,
        name: 'notification_service',
      );
    }
  }

  @override
  void dispose() {
    stopPolling();
    _controller.close();
    super.dispose();
  }
}
