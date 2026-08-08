import 'package:flutter/material.dart';

/// Rendering and deep-link resolution for notification codes.
///
/// Keep this in sync with the API docs (topic `notifications`): every code
/// needs a title, body, icon and a deep-link target.
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
      'calendar.event_created' => 'Neues Kalender-Event',
      'calendar.event_updated' => 'Kalender-Event geändert',
      'calendar.participant_added' => 'Zu Kalender-Event hinzugefügt',
      'location_sharing.started' => 'Live-Standort wird geteilt',
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
      'calendar.event_created' =>
        payload['title'] ?? 'Du wurdest zu einem Event eingeladen.',
      'calendar.event_updated' =>
        payload['title'] ?? 'Ein Kalender-Event wurde geändert.',
      'calendar.participant_added' =>
        payload['title'] ?? 'Du wurdest zu einem Kalender-Event hinzugefügt.',
      'location_sharing.started' =>
        '${payload['ownerDisplayName'] ?? 'Ein Kontakt'} teilt seinen '
            'Live-Standort.',
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
      'calendar.event_created' => Icons.event_available_rounded,
      'calendar.event_updated' => Icons.event_note_rounded,
      'calendar.participant_added' => Icons.person_add_alt_1_rounded,
      'location_sharing.started' => Icons.my_location_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  /// Route to navigate to when the notification is opened, or `null` when
  /// there is no dedicated target (the inbox sheet is shown instead).
  static String? route(String code, Map<String, dynamic> payload) {
    if (code.startsWith('calendar.')) {
      final eventId = payload['calendarEventId'] as String?;
      if (eventId != null && eventId.isNotEmpty) return '/kalender/$eventId';
      return null;
    }
    if (code.startsWith('admin.')) {
      // API deep-link values are English keys, not client routes.
      return switch (payload['deepLink'] as String?) {
        'home' => '/home',
        'travel' => '/reisen',
        'events' => '/kalender',
        'profile' => '/einstellungen/profil',
        'settings' => '/einstellungen',
        'friends' => '/kontakte',
        'discover' => '/entdecken',
        'feedback' => '/feedback',
        _ => null,
      };
    }
    return null;
  }
}
