import 'package:flutter/material.dart';

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
      'location_sharing.started' => 'Standort wird geteilt',
      _ => 'Benachrichtigung',
    };
  }

  static String body(String code, Map<String, dynamic> payload) {
    final custom = payload['body'] as String?;
    if (custom != null && custom.isNotEmpty) return custom;
    return switch (code) {
      'admin.system_update' => 'Es gibt ein System-Update.',
      'admin.new_feature' => 'Eine neue Funktion ist verfügbar.',
      'admin.maintenance' => 'Wartungsarbeiten wurden durchgeführt.',
      'admin.welcome' => 'Willkommen bei Sinclear!',
      'admin.test' => 'Dies ist eine Test-Benachrichtigung.',
      'location_sharing.started' => '${payload['ownerDisplayName']} teilt jetzt seinen Standort mit dir.',
      _ => 'Du hast eine neue Benachrichtigung.',
    };
  }

  static IconData icon(String code, Map<String, dynamic> payload) {
    return switch (code) {
      'admin.system_update' => Icons.system_update_rounded,
      'admin.new_feature' => Icons.auto_awesome_rounded,
      'admin.maintenance' => Icons.build_rounded,
      'admin.welcome' => Icons.waving_hand_rounded,
      'admin.test' => Icons.science_rounded,
      'location_sharing.started' => Icons.location_on_rounded,
      _ => Icons.notifications_rounded,
    };
  }
}
