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

  /// Registrierung beim Zustelldienst fehlgeschlagen. Die bisherige Methode
  /// bleibt aktiv.
  registrationFailed,

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
  /// Die bisherige Methode bleibt aktiv, bis die neue nachweislich
  /// funktioniert (Endpoint bzw. Token serverseitig registriert). Erst dann
  /// werden Polling, UnifiedPush und FCM der anderen Methoden beendet.
  Future<NotificationMethodOutcome> apply(NotificationMethod method) async {
    switch (method) {
      case NotificationMethod.polling:
        final started = await foregroundPolling.start();
        if (!started) return NotificationMethodOutcome.permissionDenied;
        notification.startPolling(getToken: getToken);
        await _deactivateOthers(NotificationMethod.polling);
        return NotificationMethodOutcome.applied;

      case NotificationMethod.unifiedPush:
        if (!await requestPermission()) {
          return NotificationMethodOutcome.permissionDenied;
        }
        await unifiedPush.init(
          token: await getToken(),
          onMessage: (item) {
            unawaited(_handleIncomingPushItem(item));
          },
        );

        if (await unifiedPush.registeredDistributor() != null) {
          if (!await unifiedPush.register()) {
            return NotificationMethodOutcome.registrationFailed;
          }
          await _deactivateOthers(NotificationMethod.unifiedPush);
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
        // Die Berechtigung wird in setup() über FirebaseMessaging angefragt —
        // kein zweiter Dialog über LocalNotificationHelper.
        final result = await fcm.setup(
          getToken: getToken,
          onWakeup: () => notification.pollOnce(getToken: getToken),
        );
        switch (result) {
          case FcmSetupResult.ready:
            await _deactivateOthers(NotificationMethod.fcm);
            return NotificationMethodOutcome.applied;
          case FcmSetupResult.permissionDenied:
            return NotificationMethodOutcome.permissionDenied;
          case FcmSetupResult.unavailable:
            return NotificationMethodOutcome.unavailable;
          case FcmSetupResult.failed:
            return NotificationMethodOutcome.registrationFailed;
        }
    }
  }

  /// Beendet alle Zustellwege außer [keep].
  ///
  /// Wird erst nach erfolgreichem Setup der neuen Methode aufgerufen, damit
  /// ein Fehlschlag die bisherige Zustellung nicht abwürgt.
  Future<void> _deactivateOthers(NotificationMethod keep) async {
    if (keep != NotificationMethod.polling) {
      await foregroundPolling.stop();
      notification.stopPolling();
    }
    if (keep != NotificationMethod.unifiedPush) {
      await unifiedPush.unregister();
    }
    if (keep != NotificationMethod.fcm) {
      await fcmPush?.unregister();
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
      if (!await unifiedPush.selectDistributor(distributor)) return false;
      await _deactivateOthers(NotificationMethod.unifiedPush);
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
