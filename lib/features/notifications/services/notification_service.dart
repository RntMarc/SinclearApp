// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../models/notification_item.dart';
import 'notification_content_resolver.dart';

class NotificationService extends ChangeNotifier {
  final ApiClient _api;

  /// Bereitet rohe Benachrichtigungen (nur `type` + Relation-IDs) für die
  /// lokale Anzeige auf: lädt fehlende Daten nach und erzeugt Titel/Text.
  final NotificationContentResolver? _contentResolver;

  Timer? _pollingTimer;
  String? _lastSeen;

  /// IDs aller bereits angezeigten Benachrichtigungen dieser Session.
  /// Bewusst nicht bei `startPolling`/`stopPolling` zurückgesetzt, damit
  /// Resume/Cold-Start-Restarts keine Duplikate anzeigen.
  final Set<String> _seenIds = {};

  final StreamController<List<NotificationItem>> _controller =
      StreamController<List<NotificationItem>>.broadcast();

  Stream<List<NotificationItem>> get notifications => _controller.stream;

  NotificationService({
    required ApiClient api,
    NotificationContentResolver? contentResolver,
  }) : _api = api,
       _contentResolver = contentResolver;

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
          final resolver = _contentResolver;
          if (resolver != null) {
            for (final item in newItems.take(3)) {
              await resolver.showLocal(item);
            }
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
