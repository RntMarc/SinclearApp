import 'package:flutter/cupertino.dart';

class NotificationTypeLabel {
  static String title(String code, Map<String, dynamic> payload) {
    final custom = payload['title'] as String?;
    if (custom != null && custom.isNotEmpty) return custom;
    return switch (code) {
      'admin.system_update' => 'System-Update',
      'admin.new_feature' => 'Neue Funktion',
      'admin.maintenance' => 'Wartung',
      'admin.welcome' => 'Willkommen',
      'admin.test' => 'Test',
      _ => 'Benachrichtigung',
    };
  }

  static String body(String code, Map<String, dynamic> payload) {
    final custom = payload['body'] as String?;
    if (custom != null && custom.isNotEmpty) return custom;
    return switch (code) {
      'admin.system_update' => 'Es gibt ein System-Update.',
      'admin.new_feature' => 'Eine neue Funktion ist verfugbar.',
      'admin.maintenance' => 'Wartungsarbeiten wurden durchgefuhrt.',
      'admin.welcome' => 'Willkommen bei Sinclear!',
      'admin.test' => 'Dies ist eine Test-Benachrichtigung.',
      _ => 'Du hast eine neue Benachrichtigung.',
    };
  }

  static IconData icon(String code, Map<String, dynamic> payload) {
    return switch (code) {
      'admin.system_update' => CupertinoIcons.gear,
      'admin.new_feature' => CupertinoIcons.sparkles,
      'admin.maintenance' => CupertinoIcons.wrench,
      'admin.welcome' => CupertinoIcons.hand_raised,
      'admin.test' => CupertinoIcons.lab_flask,
      _ => CupertinoIcons.bell,
    };
  }
}
