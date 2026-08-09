import 'package:flutter/material.dart';

/// Rendering and deep-link resolution for notification codes.
///
/// The API does NOT provide deep links (except admin codes). The client MUST
/// derive the target route from the notification `code` and the IDs in
/// `payload`. Keep this in sync with the API notification service.
class NotificationTypeLabel {
  static String title(String code, Map<String, dynamic> payload) {
    final custom = payload['title'] as String?;
    if (custom != null && custom.isNotEmpty) return custom;

    // Domain-specific titles
    if (code.startsWith('travel.')) {
      return switch (code) {
        'travel.event_created' => 'Neues Reise-Event',
        'travel.event_updated' => 'Reise-Event geändert',
        'travel.ticket_created' => 'Neues Ticket',
        'travel.member_added' => 'Neues Reisemitglied',
        _ => 'Reise-Benachrichtigung',
      };
    }
    if (code.startsWith('calendar.')) {
      return switch (code) {
        'calendar.event_created' => 'Neues Kalender-Event',
        'calendar.event_updated' => 'Kalender-Event geändert',
        'calendar.participant_added' => 'Zu Kalender-Event hinzugefügt',
        _ => 'Kalender-Benachrichtigung',
      };
    }
    if (code.startsWith('forum.')) {
      return switch (code) {
        'forum.post_created' => 'Neuer Forumsbeitrag',
        'forum.reply_created' => 'Neue Antwort',
        'forum.mention' => 'Erwähnung im Forum',
        _ => 'Forum-Benachrichtigung',
      };
    }
    if (code.startsWith('recipe.')) {
      return switch (code) {
        'recipe.comment' => 'Neuer Kommentar',
        'recipe.fork' => 'Rezept geforkt',
        _ => 'Rezept-Benachrichtigung',
      };
    }
    if (code.startsWith('admin.')) {
      return switch (code) {
        'admin.system_update' => 'System-Update',
        'admin.new_feature' => 'Neue Funktion',
        'admin.maintenance' => 'Wartung',
        'admin.welcome' => 'Willkommen',
        'admin.test' => 'Test',
        'admin.custom' => payload['title'] ?? 'Admin-Nachricht',
        _ => 'Admin-Benachrichtigung',
      };
    }
    return switch (code) {
      'location_sharing.started' => 'Live-Standort wird geteilt',
      'changelog.new_entry' => 'Neuer Changelog-Eintrag',
      'like.received' => 'Like erhalten',
      'friend.request' => 'Freundschaftsanfrage',
      _ => 'Benachrichtigung',
    };
  }

  static String body(String code, Map<String, dynamic> payload) {
    final custom = payload['body'] as String?;
    if (custom != null && custom.isNotEmpty) return custom;

    // Travel
    if (code.startsWith('travel.')) {
      final tripTitle = payload['tripTitle'] as String?;
      final eventTitle = payload['eventTitle'] as String?;
      final ticketTitle = payload['ticketTitle'] as String?;
      final memberName = payload['memberDisplayName'] as String?;
      return switch (code) {
        'travel.event_created' =>
          tripTitle != null
              ? 'In "$tripTitle": $eventTitle'
              : 'Du wurdest zu einem Event eingeladen.',
        'travel.event_updated' =>
          tripTitle != null
              ? 'In "$tripTitle": $eventTitle wurde geändert.'
              : 'Ein Reise-Event wurde geändert.',
        'travel.ticket_created' =>
          tripTitle != null
              ? 'In "$tripTitle": $ticketTitle'
              : 'Ein neues Ticket wurde hinzugefügt.',
        'travel.member_added' =>
          memberName != null
              ? '$memberName wurde zur Reise hinzugefügt.'
              : 'Ein neues Mitglied wurde zur Reise hinzugefügt.',
        _ => 'Neue Aktivität in deiner Reise.',
      };
    }

    // Calendar
    if (code.startsWith('calendar.')) {
      final title = payload['title'] as String?;
      return switch (code) {
        'calendar.event_created' =>
          title ?? 'Du wurdest zu einem Event eingeladen.',
        'calendar.event_updated' =>
          title ?? 'Ein Kalender-Event wurde geändert.',
        'calendar.participant_added' =>
          title ?? 'Du wurdest zu einem Kalender-Event hinzugefügt.',
        _ => 'Kalender-Aktualisierung.',
      };
    }

    // Forum
    if (code.startsWith('forum.')) {
      final forumTitle = payload['forumTitle'] as String?;
      final postTitle = payload['postTitle'] as String?;
      final actorName = payload['actorDisplayName'] as String?;
      return switch (code) {
        'forum.post_created' =>
          forumTitle != null
              ? 'In "$forumTitle": $postTitle'
              : 'Ein neuer Beitrag wurde erstellt.',
        'forum.reply_created' =>
          postTitle != null
              ? '$actorName hat geantwortet: $postTitle'
              : '$actorName hat geantwortet.',
        'forum.mention' =>
          actorName != null
              ? '$actorName hat dich erwähnt.'
              : 'Du wurdest erwähnt.',
        _ => 'Forum-Aktivität.',
      };
    }

    // Recipe
    if (code.startsWith('recipe.')) {
      final recipeTitle = payload['recipeTitle'] as String?;
      final actorName = payload['actorDisplayName'] as String?;
      return switch (code) {
        'recipe.comment' =>
          recipeTitle != null
              ? '$actorName hat kommentiert: $recipeTitle'
              : '$actorName hat dein Rezept kommentiert.',
        'recipe.fork' =>
          recipeTitle != null
              ? '$actorName hat "$recipeTitle" geforkt.'
              : '$actorName hat dein Rezept geforkt.',
        _ => 'Rezept-Aktivität.',
      };
    }

    // Admin
    if (code.startsWith('admin.')) {
      return switch (code) {
        'admin.system_update' => 'Es gibt ein System-Update.',
        'admin.new_feature' => 'Eine neue Funktion ist verfügbar.',
        'admin.maintenance' => 'Wartungsarbeiten wurden durchgeführt.',
        'admin.welcome' => 'Willkommen bei Sinclear!',
        'admin.test' => 'Dies ist eine Test-Benachrichtigung.',
        'admin.custom' => payload['body'] ?? 'Admin-Nachricht.',
        _ => 'Admin-Benachrichtigung.',
      };
    }

    // Others
    return switch (code) {
      'location_sharing.started' =>
        '${payload['ownerDisplayName'] ?? 'Ein Kontakt'} teilt seinen '
            'Live-Standort.',
      'changelog.new_entry' => 'Ein neuer Changelog-Eintrag ist verfügbar.',
      'like.received' =>
        '${payload['actorDisplayName'] ?? 'Jemand'} hat deinen Beitrag geliked.',
      'friend.request' =>
        '${payload['actorDisplayName'] ?? 'Jemand'} möchte dich als Freund hinzufügen.',
      _ => 'Du hast eine neue Benachrichtigung.',
    };
  }

  static IconData icon(String code, Map<String, dynamic> payload) {
    if (code.startsWith('travel.')) {
      return switch (code) {
        'travel.event_created' => Icons.event_available_rounded,
        'travel.event_updated' => Icons.event_note_rounded,
        'travel.ticket_created' => Icons.confirmation_number_rounded,
        'travel.member_added' => Icons.person_add_rounded,
        _ => Icons.travel_explore_rounded,
      };
    }
    if (code.startsWith('calendar.')) {
      return switch (code) {
        'calendar.event_created' => Icons.event_available_rounded,
        'calendar.event_updated' => Icons.event_note_rounded,
        'calendar.participant_added' => Icons.person_add_alt_1_rounded,
        _ => Icons.calendar_month_rounded,
      };
    }
    if (code.startsWith('forum.')) {
      return switch (code) {
        'forum.post_created' => Icons.forum_rounded,
        'forum.reply_created' => Icons.reply_rounded,
        'forum.mention' => Icons.alternate_email_rounded,
        _ => Icons.forum_rounded,
      };
    }
    if (code.startsWith('recipe.')) {
      return switch (code) {
        'recipe.comment' => Icons.comment_rounded,
        'recipe.fork' => Icons.content_copy_rounded,
        _ => Icons.menu_book_rounded,
      };
    }
    if (code.startsWith('admin.')) {
      return switch (code) {
        'admin.system_update' => Icons.system_update_rounded,
        'admin.new_feature' => Icons.auto_awesome_rounded,
        'admin.maintenance' => Icons.build_rounded,
        'admin.welcome' => Icons.waving_hand_rounded,
        'admin.test' => Icons.science_rounded,
        'admin.custom' => Icons.admin_panel_settings_rounded,
        _ => Icons.admin_panel_settings_rounded,
      };
    }
    return switch (code) {
      'location_sharing.started' => Icons.my_location_rounded,
      'changelog.new_entry' => Icons.description_rounded,
      'like.received' => Icons.favorite_rounded,
      'friend.request' => Icons.person_add_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  /// Route to navigate to when the notification is opened, or `null` when
  /// there is no dedicated target (the inbox sheet is shown instead).
  ///
  /// Derives the route from the notification `code` and the IDs in `payload`.
  static String? route(String code, Map<String, dynamic> payload) {
    // Travel: tripId → /reisen/{tripId} (TripDetailScreen shows events/tickets)
    if (code.startsWith('travel.')) {
      final tripId = payload['tripId'] as String?;
      if (tripId != null && tripId.isNotEmpty) return '/reisen/$tripId';
      return null;
    }

    // Calendar: calendarEventId → /kalender/{id}
    if (code.startsWith('calendar.')) {
      final eventId = payload['calendarEventId'] as String?;
      if (eventId != null && eventId.isNotEmpty) return '/kalender/$eventId';
      return null;
    }

    // Forum: forumId (+ optional postId) → /forum/{forumId} or post detail
    if (code.startsWith('forum.')) {
      final forumId = payload['forumId'] as String?;
      final postId = payload['postId'] as String?;
      if (forumId != null && forumId.isNotEmpty) {
        if (postId != null && postId.isNotEmpty) {
          return '/forum/$forumId/beitrag/$postId';
        }
        return '/forum/$forumId';
      }
      return null;
    }

    // Recipe: recipeId → /rezepte/{id}
    if (code.startsWith('recipe.')) {
      final recipeId = payload['recipeId'] as String?;
      if (recipeId != null && recipeId.isNotEmpty) return '/rezepte/$recipeId';
      return null;
    }

    // Friend: actorId → /kontakte/{actorId}
    if (code == 'friend.request') {
      final actorId = payload['actorId'] as String?;
      if (actorId != null && actorId.isNotEmpty) return '/kontakte/$actorId';
      return null;
    }

    // Admin: deepLink from payload (API provides German route paths)
    if (code.startsWith('admin.')) {
      final deepLink = payload['deepLink'] as String?;
      if (deepLink != null && deepLink.isNotEmpty) {
        return deepLink.startsWith('/') ? deepLink : '/$deepLink';
      }
      return null;
    }

    // Codes without dedicated screens → open inbox
    return null;
  }
}
