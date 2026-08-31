import 'package:flutter/material.dart';

import '../../features/notifications/models/notification_item.dart';

/// Übersetzt Benachrichtigungstypen in Titel, Text, Icon und Navigationsziel.
///
/// Vertrag (siehe `test/notification_config_test.dart` und die API-Doku des
/// SinclearAPI-MCP, Topic `notifications`): Die API liefert pro
/// Benachrichtigung `type`, `data` sowie servergenerierte Titel/Texte. Diese
/// Klasse bildet `type` und Relation-IDs rein lokal auf deutsche
/// Fallback-Texte und Routen ab — für den Fall, dass die API-Titel/-Texte
/// fehlen (z. B. alte Payloads) und für die Anreicherung nicht nachgeladen
/// werden kann.
///
/// Unterstützte Typen: `forum_reply`, `forum_comment`, `forum_post`,
/// `forum_upvote`, `story_post`, `direct_message`,
/// `trip_user_added`, `trip_user_added_others`, `trip_event_added`,
/// `trip_event_user_added`, `trip_event_user_added_others`,
/// `trip_event_info_changed`, `trip_event_ticket_added`,
/// `trip_ticket_added`, `trip_accommodation_added`,
/// `trip_subscription_added`, `trip_info_changed`,
/// `standalone_event_user_added`, `standalone_event_user_added_others`,
/// `standalone_event_info_changed`, `standalone_event_ticket_added`
/// (siehe API-Doku). Unbekannte Typen liefern generische Standardwerte,
/// `route` gibt dann `null` zurück (Aufrufer öffnet die Inbox bzw. bis zu
/// deren Umsetzung `/home`).
class NotificationTypeLabel {
  const NotificationTypeLabel._();

  static const _tripTypes = {
    'trip_user_added',
    'trip_user_added_others',
    'trip_event_added',
    'trip_event_user_added',
    'trip_event_user_added_others',
    'trip_event_info_changed',
    'trip_event_ticket_added',
    'trip_ticket_added',
    'trip_accommodation_added',
    'trip_subscription_added',
    'trip_info_changed',
  };

  static const _standaloneEventTypes = {
    'standalone_event_user_added',
    'standalone_event_user_added_others',
    'standalone_event_info_changed',
    'standalone_event_ticket_added',
  };

  /// Liefert die deutsche Route für eine Benachrichtigung, aufgebaut aus
  /// den Relation-IDs in [data]. `null`, wenn der Typ unbekannt ist oder
  /// Pflicht-Relationen fehlen.
  static String? route(String type, List<NotificationRelation> data) {
    return switch (type) {
      'forum_reply' || 'forum_comment' || 'forum_post' || 'forum_upvote' =>
        _forumRoute(data),
      'story_post' => _storyRoute(data),
      'direct_message' => _directMessageRoute(data),
      _ when _tripTypes.contains(type) => _tripRoute(data),
      _ when _standaloneEventTypes.contains(type) => _standaloneEventRoute(
        data,
      ),
      _ => null,
    };
  }

  /// Lokaler Fallback-Titel für die Benachrichtigung (spiegelt die
  /// API-generierten Titel, siehe API-Doku `notifications/types`).
  static String title(String type) {
    return switch (type) {
      'forum_reply' => 'Neue Antwort auf deinen Kommentar',
      'forum_comment' => 'Neuer Kommentar zu deinem Beitrag',
      'forum_post' => 'Neuer Beitrag im Forum',
      'forum_upvote' => 'Neue Bewertung',
      'story_post' => 'Neue Story',
      'direct_message' => 'Neue Nachricht',
      'trip_user_added' => 'Du wurdest zu einer Reise hinzugefügt',
      'trip_user_added_others' => 'Neuer Teilnehmer auf der Reise',
      'trip_event_added' => 'Neues Event auf der Reise',
      'trip_event_user_added' => 'Du wurdest zu einem Event hinzugefügt',
      'trip_event_user_added_others' => 'Neuer Teilnehmer beim Event',
      'trip_event_info_changed' => 'Event-Informationen geändert',
      'trip_event_ticket_added' => 'Neues Ticket für das Event',
      'trip_ticket_added' => 'Neues Ticket für die Reise',
      'trip_accommodation_added' => 'Hotel-Zuweisung',
      'trip_subscription_added' => 'Neues Abo verknüpft',
      'trip_info_changed' => 'Reise-Informationen geändert',
      'standalone_event_user_added' => 'Du wurdest zu einem Event hinzugefügt',
      'standalone_event_user_added_others' => 'Neuer Teilnehmer beim Event',
      'standalone_event_info_changed' => 'Event-Informationen geändert',
      'standalone_event_ticket_added' => 'Neues Ticket für das Event',
      // Vereinheitlichte Preference-Schlüssel (nur Einstellungen): gelten
      // für Reise-Events und eigenständige Events gleichermaßen.
      'event_user_added' => 'Du wurdest zu einem Event hinzugefügt',
      'event_user_added_others' => 'Neuer Teilnehmer beim Event',
      'event_info_changed' => 'Event-Informationen geändert',
      'event_ticket_added' => 'Neues Ticket für das Event',
      _ => 'Neue Mitteilung',
    };
  }

  /// Generalisierter Anzeigetext, der ohne Nachladen weiterer Daten
  /// auskommt — Fallback, wenn weder API-Text vorliegt noch die
  /// Anreicherung über die API gelingt.
  static String fallbackBody(String type) {
    return switch (type) {
      'forum_reply' => 'Jemand hat auf deinen Kommentar geantwortet.',
      'forum_comment' => 'Jemand hat deinen Beitrag kommentiert.',
      'forum_post' => 'Jemand hat einen neuen Beitrag im Forum veröffentlicht.',
      'forum_upvote' => 'Jemand hat deinen Beitrag positiv bewertet.',
      'story_post' => 'Jemand hat eine neue Story veröffentlicht.',
      'direct_message' => 'Du hast eine neue Nachricht.',
      'trip_user_added' => 'Du wurdest zu einer Reise hinzugefügt.',
      'trip_user_added_others' =>
        'Ein neuer Teilnehmer wurde zur Reise hinzugefügt.',
      'trip_event_added' => 'Ein neues Event wurde zur Reise hinzugefügt.',
      'trip_event_user_added' => 'Du wurdest zu einem Event hinzugefügt.',
      'trip_event_user_added_others' =>
        'Ein neuer Teilnehmer wurde zum Event hinzugefügt.',
      'trip_event_info_changed' => 'Die Event-Informationen wurden geändert.',
      'trip_event_ticket_added' =>
        'Ein neues Ticket wurde zum Event hinzugefügt.',
      'trip_ticket_added' => 'Ein neues Ticket wurde zur Reise hinzugefügt.',
      'trip_accommodation_added' => 'Dir wurde ein Hotel zugewiesen.',
      'trip_subscription_added' => 'Ein Abo wurde mit der Reise verknüpft.',
      'trip_info_changed' => 'Die Reise-Informationen wurden geändert.',
      'standalone_event_user_added' => 'Du wurdest zu einem Event hinzugefügt.',
      'standalone_event_user_added_others' =>
        'Ein neuer Teilnehmer wurde zum Event hinzugefügt.',
      'standalone_event_info_changed' =>
        'Die Event-Informationen wurden geändert.',
      'standalone_event_ticket_added' =>
        'Ein neues Ticket wurde zum Event hinzugefügt.',
      _ => 'Du hast eine neue Benachrichtigung.',
    };
  }

  /// Icon für die Benachrichtigung.
  static IconData icon(String type) {
    return switch (type) {
      'forum_reply' || 'forum_comment' || 'forum_post' || 'forum_upvote' =>
        Icons.forum_rounded,
      'story_post' => Icons.auto_stories_rounded,
      'direct_message' => Icons.chat_rounded,
      'trip_user_added' ||
      'trip_user_added_others' ||
      'trip_info_changed' => Icons.card_travel,
      'trip_event_added' ||
      'trip_event_user_added' ||
      'trip_event_user_added_others' => Icons.event,
      'trip_event_info_changed' ||
      'standalone_event_info_changed' => Icons.info_outline,
      'trip_event_ticket_added' ||
      'trip_ticket_added' ||
      'standalone_event_ticket_added' => Icons.confirmation_num,
      'trip_accommodation_added' => Icons.hotel,
      'trip_subscription_added' => Icons.receipt_long,
      'standalone_event_user_added' ||
      'standalone_event_user_added_others' => Icons.event,
      'event_user_added' || 'event_user_added_others' => Icons.event,
      'event_info_changed' => Icons.info_outline,
      'event_ticket_added' => Icons.confirmation_num,
      _ => Icons.notifications_rounded,
    };
  }

  /// `/forum/{parent_forum}/beitrag/{parent_post}` — beide Relationen sind
  /// laut API-Doku bei `forum_reply` und `forum_comment` Pflicht; ohne sie
  /// ist das Ziel nicht bestimmbar.
  static String? _forumRoute(List<NotificationRelation> data) {
    final forumId = _identifierFor(data, 'parent_forum');
    final postId = _identifierFor(data, 'parent_post');
    if (forumId == null || postId == null) return null;
    return '/forum/$forumId/beitrag/$postId';
  }

  /// `/stories/{story}` — die Story-ID ist laut API-Doku bei `story_post`
  /// Pflicht; ohne sie ist das Ziel nicht bestimmbar.
  static String? _storyRoute(List<NotificationRelation> data) {
    final storyId = _identifierFor(data, 'story');
    if (storyId == null) return null;
    return '/stories/$storyId';
  }

  /// `/chat/{conversation}` — die Konversations-ID ist bei
  /// `direct_message` Pflicht; ohne sie ist das Ziel nicht bestimmbar.
  static String? _directMessageRoute(List<NotificationRelation> data) {
    final conversationId = _identifierFor(data, 'conversation');
    if (conversationId == null) return null;
    return '/chat/$conversationId';
  }

  /// `/reisen/{trip}` — die Trip-ID ist bei allen `trip_*`-Typen Pflicht.
  static String? _tripRoute(List<NotificationRelation> data) {
    final tripId = _identifierFor(data, 'trip');
    if (tripId == null) return null;
    return '/reisen/$tripId';
  }

  /// `/reisen/einzelevent/{event}` — die Event-ID ist bei allen
  /// `standalone_event_*`-Typen Pflicht.
  static String? _standaloneEventRoute(List<NotificationRelation> data) {
    final eventId = _identifierFor(data, 'event');
    if (eventId == null) return null;
    return '/reisen/einzelevent/$eventId';
  }

  /// Kategorie für die Gruppierung im Einstellungen-Screen. `null` für
  /// unbekannte Typen — unbekannte Typen werden nicht angezeigt.
  ///
  /// Arbeitet auf den **Preference-Schlüsseln** des Preferences-Endpoints
  /// (`GET/PUT /notifications/preferences`). Event-Benachrichtigungen werden
  /// dort vereinheitlicht: die internen Reise-/Standalone-Varianten
  /// (`standalone_event_*`, `trip_event_*`) tauchen in den Präferenzen nicht
  /// auf, sondern nur die gemeinsamen Schlüssel `event_user_added`,
  /// `event_user_added_others`, `event_ticket_added` und `event_info_changed`.
  static String? category(String type) {
    return switch (type) {
      'forum_reply' ||
      'forum_comment' ||
      'forum_post' ||
      'forum_upvote' => 'Forum',
      'story_post' => 'Stories',
      'direct_message' => 'Chat',
      'trip_user_added' ||
      'trip_user_added_others' ||
      'trip_info_changed' ||
      'trip_event_added' => 'Reisen',
      'event_user_added' ||
      'event_user_added_others' ||
      'event_info_changed' => 'Events',
      'trip_ticket_added' || 'event_ticket_added' => 'Tickets',
      'trip_accommodation_added' => 'Unterkunft',
      'trip_subscription_added' => 'Abos',
      _ => null,
    };
  }

  /// Schlüssel der Denylist (`customData`) für `custom`-fähige Typen —
  /// deterministisch laut API-Doku `notifications`: `forumIds` bei den
  /// Forum-Typen, `userIds` bei `story_post`. `null` für alle anderen.
  static String? customDataKey(String type) {
    return switch (type) {
      'forum_reply' || 'forum_comment' || 'forum_post' => 'forumIds',
      'story_post' => 'userIds',
      'direct_message' => 'userIds',
      _ => null,
    };
  }

  static String? _identifierFor(
    List<NotificationRelation> data,
    String relation,
  ) {
    for (final entry in data) {
      if (entry.relation == relation && entry.identifier.isNotEmpty) {
        return entry.identifier;
      }
    }
    return null;
  }
}
