import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zustell-Methode für Benachrichtigungen auf dem Gerät.
enum NotificationMethod {
  /// Regelmäßiges Abrufen der API im Vordergrund/Hintergrund der App.
  polling,

  /// Push über einen UnifiedPush-Distributor (nur Android).
  unifiedPush,

  /// Google FCM – geplant, noch nicht verfügbar.
  fcm,
}

extension NotificationMethodX on NotificationMethod {
  String get label => switch (this) {
    NotificationMethod.polling => 'Polling',
    NotificationMethod.unifiedPush => 'UnifiedPush',
    NotificationMethod.fcm => 'FCM',
  };

  String get description => switch (this) {
    NotificationMethod.polling => 'Regelmäßiges Abrufen im Hintergrund',
    NotificationMethod.unifiedPush =>
      'Push über einen Distributor (z. B. ntfy)',
    NotificationMethod.fcm => 'Google Firebase Cloud Messaging',
  };

  /// Auf dieser Plattform wählbare Methoden.
  static List<NotificationMethod> availableFor() {
    if (kIsWeb) return const [NotificationMethod.polling];
    if (Platform.isAndroid) {
      return const [NotificationMethod.polling, NotificationMethod.unifiedPush];
    }
    return const [NotificationMethod.polling];
  }
}

/// Lokale Persistenz der gewählten Benachrichtigungs-Methode.
class NotificationPreference {
  const NotificationPreference._();

  static const _key = 'notification_method';

  /// Standard-Methode: auf Android UnifiedPush, sonst Polling —
  /// entspricht dem bisherigen Verhalten (Android richtete Push ein).
  static NotificationMethod defaultMethod() {
    if (kIsWeb) return NotificationMethod.polling;
    if (Platform.isAndroid) return NotificationMethod.unifiedPush;
    return NotificationMethod.polling;
  }

  static Future<NotificationMethod> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    return NotificationMethod.values.asNameMap()[name] ?? defaultMethod();
  }

  static Future<void> save(NotificationMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, method.name);
  }
}
