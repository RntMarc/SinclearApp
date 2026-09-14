import 'dart:async';
import 'dart:developer' as developer;

import '../../../core/notifications/local_notification_helper.dart';
import '../../settings/models/notification_preference.dart';
import '../models/notification_item.dart';
import 'foreground_polling_service.dart';
import 'notification_service.dart';
import 'unified_push_service.dart';

/// Ergebnis eines [NotificationMethodCoordinator.apply]-Aufrufs.
enum NotificationMethodOutcome {
  /// Methode erfolgreich eingerichtet.
  applied,

  /// Benachrichtigungs-Berechtigung fehlt; nicht fortfahren.
  permissionDenied,

  /// Installierte Distributoren gefunden — Auswahl nötig.
  needsDistributor,

  /// Kein Distributor installiert; UnifiedPush kann nicht genutzt werden.
  noDistributor,

  /// Methode nicht verfügbar (FCM).
  unavailable,
}

/// Einzige Stelle für Auswahl → Prüfung → Setup einer Zustell-Methode.
///
/// Bündelt die zuvor in `notification_settings_screen.dart` und
/// `verify_screen.dart` duplizierte Logik. UI (Distributor-Picker,
/// Fehlermeldungen) bleibt beim Aufrufer, der das [NotificationMethodOutcome]
/// auswertet.
class NotificationMethodCoordinator {
  final UnifiedPushService unifiedPush;
  final NotificationService notification;
  final ForegroundPollingService foregroundPolling;
  final Future<String> Function() getToken;

  /// Wird bei eingehenden UnifiedPush-Nachrichten aufgerufen (Anzeige).
  final void Function(NotificationItem item)? onPushMessage;

  List<String> _pendingDistributors = const [];

  NotificationMethodCoordinator({
    required this.unifiedPush,
    required this.notification,
    required this.foregroundPolling,
    required this.getToken,
    this.onPushMessage,
  });

  /// Zuletzt gefundene Distributoren (nach [NotificationMethodOutcome
  /// .needsDistributor]).
  List<String> get pendingDistributors => _pendingDistributors;

  /// Richtet [method] ein und prüft die Voraussetzungen.
  ///
  /// [previous] ist die zuvor aktive Methode, damit ein Wechsel von
  /// UnifiedPush zu Polling den Distributor sauber abmeldet.
  Future<NotificationMethodOutcome> apply(
    NotificationMethod method, {
    NotificationMethod? previous,
  }) async {
    switch (method) {
      case NotificationMethod.polling:
        if (previous == NotificationMethod.unifiedPush) {
          await unifiedPush.unregister();
        }
        final started = await foregroundPolling.start();
        if (!started) return NotificationMethodOutcome.permissionDenied;
        notification.startPolling(getToken: getToken);
        return NotificationMethodOutcome.applied;

      case NotificationMethod.unifiedPush:
        await foregroundPolling.stop();
        notification.stopPolling();
        await LocalNotificationHelper.requestPermission();
        unifiedPush.init(
          token: await getToken(),
          onMessage: (item) {
            notification.registerIncoming(item);
            onPushMessage?.call(item);
          },
        );

        if (await unifiedPush.registeredDistributor() != null) {
          await unifiedPush.register();
          return NotificationMethodOutcome.applied;
        }

        _pendingDistributors = await unifiedPush.availableDistributors();
        if (_pendingDistributors.isEmpty) {
          return NotificationMethodOutcome.noDistributor;
        }
        return NotificationMethodOutcome.needsDistributor;

      case NotificationMethod.fcm:
        return NotificationMethodOutcome.unavailable;
    }
  }

  /// Registriert die App beim gewählten Distributor.
  Future<void> selectDistributor(String distributor) async {
    try {
      await unifiedPush.selectDistributor(distributor);
    } catch (e, st) {
      developer.log(
        'Failed to select distributor',
        error: e,
        stackTrace: st,
        name: 'notification_method',
      );
    }
  }
}
