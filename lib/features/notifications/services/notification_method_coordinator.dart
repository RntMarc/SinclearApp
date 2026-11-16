import 'dart:async';
import 'dart:developer' as developer;

import '../../../core/notifications/local_notification_helper.dart';
import '../../settings/models/notification_preference.dart';
import '../models/notification_item.dart';
import 'fcm_push_service.dart';
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

  /// Methode nicht verfügbar (z. B. FCM ohne Google Play Services).
  unavailable,
}

/// Einzige Stelle für Auswahl → Prüfung → Setup einer Zustell-Methode.
///
/// Bündelt die Setup- und Wechsel-Logik zwischen Polling, UnifiedPush und FCM
/// (nur Android; Web nutzt immer Browser-Web-Push).
class NotificationMethodCoordinator {
  final UnifiedPushService unifiedPush;
  final FcmPushService? fcmPush;
  final NotificationService notification;
  final ForegroundPollingService foregroundPolling;
  final Future<String> Function() getToken;

  /// Wird bei eingehenden UnifiedPush-Nachrichten aufgerufen (Anzeige).
  final void Function(NotificationItem item)? onPushMessage;

  /// Fragt die Benachrichtigungs-Berechtigung des Geräts an. Injizierbar, damit
  /// Tests die Berechtigung ohne Plugin steuern können.
  final Future<bool> Function() requestPermission;

  List<String> _pendingDistributors = const [];

  NotificationMethodCoordinator({
    required this.unifiedPush,
    this.fcmPush,
    required this.notification,
    required this.foregroundPolling,
    required this.getToken,
    this.onPushMessage,
    Future<bool> Function()? requestPermission,
  }) : requestPermission =
           requestPermission ?? LocalNotificationHelper.requestPermission;

  /// Zuletzt gefundene Distributoren (nach [NotificationMethodOutcome
  /// .needsDistributor]).
  List<String> get pendingDistributors => _pendingDistributors;

  /// Richtet [method] ein und prüft die Voraussetzungen.
  ///
  /// [previous] ist die zuvor aktive Methode, damit ein Wechsel die alte
  /// Subscription bzw. den alten Hintergrunddienst sauber beendet.
  Future<NotificationMethodOutcome> apply(
    NotificationMethod method, {
    NotificationMethod? previous,
  }) async {
    switch (method) {
      case NotificationMethod.polling:
        if (previous == NotificationMethod.unifiedPush) {
          await unifiedPush.unregister();
        } else if (previous == NotificationMethod.fcm) {
          await fcmPush?.unregister();
        }
        final started = await foregroundPolling.start();
        if (!started) return NotificationMethodOutcome.permissionDenied;
        notification.startPolling(getToken: getToken);
        return NotificationMethodOutcome.applied;

      case NotificationMethod.unifiedPush:
        await foregroundPolling.stop();
        notification.stopPolling();
        if (previous == NotificationMethod.fcm) {
          await fcmPush?.unregister();
        }
        if (!await requestPermission()) {
          return NotificationMethodOutcome.permissionDenied;
        }
        unifiedPush.init(
          token: await getToken(),
          onMessage: (item) {
            unawaited(_handleIncomingPushItem(item));
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
        final fcm = fcmPush;
        if (fcm == null) return NotificationMethodOutcome.unavailable;
        await foregroundPolling.stop();
        notification.stopPolling();
        if (previous == NotificationMethod.unifiedPush) {
          await unifiedPush.unregister();
        }
        if (!await requestPermission()) {
          return NotificationMethodOutcome.permissionDenied;
        }
        final ok = await fcm.setup(
          getToken: getToken,
          onWakeup: () => notification.pollOnce(getToken: getToken),
        );
        return ok
            ? NotificationMethodOutcome.applied
            : NotificationMethodOutcome.unavailable;
    }
  }

  Future<void> _handleIncomingPushItem(NotificationItem item) async {
    final shouldShow = await notification.registerIncoming(item);
    if (shouldShow) {
      onPushMessage?.call(item);
    }
  }

  /// Registriert die App beim gewählten Distributor.
  ///
  /// Liefert `false`, wenn die Registrierung fehlschlägt — dann darf das Setup
  /// nicht als erfolgreich gelten.
  Future<bool> selectDistributor(String distributor) async {
    try {
      await unifiedPush.selectDistributor(distributor);
      return true;
    } catch (e, st) {
      developer.log(
        'Failed to select distributor',
        error: e,
        stackTrace: st,
        name: 'notification_method',
      );
      return false;
    }
  }
}
