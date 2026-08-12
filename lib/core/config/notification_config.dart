import 'package:flutter/material.dart';

/// Übersetzt Benachrichtigungstypen in Titel, Text, Icon und Navigationsziel.
///
/// Vertrag (siehe `test/notification_config_test.dart` und
/// `docs/notifications/readme.md` der API): Jeder Typ-Code (`forum_reply`,
/// `travel.event_created`, …) wird auf eine deutsche Route abgebildet, sofern
/// der zugehörige Screen existiert. `null` als Route bedeutet: keine
/// dedizierte Seite — der Aufrufer öffnet die Inbox (oder einen Fallback).
class NotificationTypeLabel {
  const NotificationTypeLabel._();

  /// Liefert die deutsche Route für eine Benachrichtigung.
  ///
  /// Prioritäten: (1) `data['route']` — entweder ein deutscher Pfad
  /// (`/forum/42`), ein englischer Deep-Link-Key (`home`, `events`, …) oder
  /// ein API-Pfad (`/calendar/…`, `/trips/…`); (2) Objekt-IDs aus `data`
  /// (`calendarEventId`, `tripId`, `forumId`/`postId`, `recipeId`,
  /// `actorId`); (3) `null` → Inbox-Fallback.
  static String? route(String type, Map<String, dynamic> data) {
    final deepLink = data['route'];
    if (deepLink is String) {
      final resolved = _resolveDeepLink(deepLink);
      if (resolved != null) return resolved;
    }

    final segment = _segment(type);
    final postId = data['postId'];
    final forumId = data['forumId'];
    final actorId = data['actorId'];

    return switch (segment) {
      'travel' => _idRoute(data['tripId'], '/reisen/'),
      'calendar' => _idRoute(data['calendarEventId'], '/kalender/'),
      'forum' when postId is String && forumId is String =>
        '/forum/$forumId/beitrag/$postId',
      'forum' => _idRoute(forumId, '/forum/'),
      'recipe' => _idRoute(data['recipeId'], '/rezepte/'),
      'friend' => _idRoute(actorId, '/kontakte/'),
      'feedback' => _idRoute(data['feedbackId'], '/feedback/'),
      'admin' => _deepLinkFromAdmin(data),
      _ => null,
    };
  }

  /// Lokaler Titel für die Benachrichtigung.
  static String title(String type, Map<String, dynamic> data) {
    final custom = data['title'];
    if (custom is String && custom.isNotEmpty) return custom;

    return switch (type) {
      'travel.event_created' => 'Neues Reise-Event',
      'travel.event_updated' => 'Reise-Event aktualisiert',
      'travel.ticket_created' => 'Neues Ticket',
      'travel.member_added' => 'Neuer Reise-Teilnehmer',
      'calendar.event_created' => 'Neues Kalender-Event',
      'calendar.event_updated' => 'Event aktualisiert',
      'calendar.participant_added' => 'Neuer Teilnehmer',
      'forum.new_post' => 'Neuer Forumsbeitrag',
      'forum.comment_replied' => 'Neue Antwort',
      'forum.post_commented' => 'Neuer Kommentar',
      'forum.mention' => 'Du wurdest erwähnt',
      'recipe.comment' => 'Neuer Kommentar',
      'recipe.fork' => 'Rezept geforkt',
      'admin.system_update' => 'System-Update',
      'admin.maintenance' => 'Wartungsarbeiten',
      'location_sharing.started' => 'Live-Standort wird geteilt',
      'changelog.new_entry' => 'Neuer Changelog-Eintrag',
      'like.received' => 'Like erhalten',
      'friend.request' => 'Freundschaftsanfrage',
      'feedback.status_changed' => 'Feedback-Status aktualisiert',
      _ => 'Neue Mitteilung',
    };
  }

  /// Anzeigetext der Benachrichtigung.
  static String body(String type, Map<String, dynamic> data) {
    final fallback = data['body'];
    if (fallback is String && fallback.isNotEmpty) return fallback;

    return switch (type) {
      'travel.event_created' =>
        'Neues Event in „${_name(data, 'tripTitle')}“: ${_name(data, 'eventTitle')}',
      'travel.event_updated' =>
        '„${_name(data, 'tripTitle')}“ wurde aktualisiert',
      'travel.ticket_created' =>
        'Neues Ticket für „${_name(data, 'tripTitle')}“',
      'travel.member_added' =>
        '${_name(data, 'actorDisplayName')} ist deiner Reise beigetreten',
      'calendar.event_created' => '„${_name(data, 'title')}“ wurde angelegt',
      'calendar.event_updated' => '„${_name(data, 'title')}“ wurde geändert',
      'calendar.participant_added' => _name(data, 'title'),
      'forum.new_post' =>
        'Neuer Beitrag von ${_name(data, 'authorDisplayName')}',
      'forum.comment_replied' =>
        '${_name(data, 'commenterDisplayName')} hat geantwortet',
      'forum.post_commented' =>
        '${_name(data, 'commenterDisplayName')} hat kommentiert',
      'forum.mention' => '${_name(data, 'actorDisplayName')} hat dich erwähnt',
      'recipe.comment' => '${_name(data, 'actorDisplayName')} hat kommentiert',
      'recipe.fork' =>
        '${_name(data, 'actorDisplayName')} hat „${_name(data, 'recipeTitle')}“ geforkt',
      'location_sharing.started' =>
        '${_name(data, 'ownerDisplayName')} teilt jetzt seinen Standort',
      'changelog.new_entry' => 'Was ist neu in Beyond',
      'like.received' =>
        '${_name(data, 'actorDisplayName')} hat deinen Beitrag geliked',
      'friend.request' =>
        '${_name(data, 'actorDisplayName')} möchte dich als Freund hinzufügen',
      'feedback.status_changed' =>
          'Dein Feedback „${_name(data, 'title')}“: ${_name(data, 'status')}',
      _ => '',
    };
  }

  /// Icon für die Benachrichtigung.
  static IconData icon(String type, Map<String, dynamic> data) {
    return switch (_segment(type)) {
      'travel' => Icons.person_add_rounded,
      'calendar' => Icons.calendar_month_rounded,
      'forum' => Icons.forum_rounded,
      'recipe' => Icons.restaurant_menu_rounded,
      'admin' => Icons.build_rounded,
      'location_sharing' => Icons.location_on_rounded,
      'changelog' => Icons.description_rounded,
      'like' => Icons.favorite_rounded,
      'friend' => Icons.person_add_rounded,
      'feedback' => Icons.feedback_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  static String _segment(String type) => type.split('.').first;

  static String _name(Map<String, dynamic> data, String key) =>
      (data[key] as String?) ?? '';

  static String? _idRoute(Object? id, String prefix) =>
      id is String && id.isNotEmpty ? '$prefix$id' : null;

  static String? _deepLinkFromAdmin(Map<String, dynamic> data) {
    final deepLink = data['deepLink'];
    return deepLink is String ? _resolveDeepLink(deepLink) : null;
  }

  /// Englische Deep-Link-Keys (API) und Pfade → deutsche Router-Pfade.
  static String? _resolveDeepLink(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('/')) {
      for (final entry in _englishPathPrefixes.entries) {
        if (trimmed.startsWith(entry.key)) {
          return '${entry.value}${trimmed.substring(entry.key.length)}';
        }
      }
      return trimmed;
    }

    return _deepLinkToRoute[trimmed];
  }

  static const _deepLinkToRoute = <String, String?>{
    'home': '/home',
    'travel': '/reisen',
    'events': '/kalender',
    'profile': '/einstellungen/profil',
    'settings': '/einstellungen',
    'friends': '/kontakte',
    'discover': '/entdecken',
    'news': '/home',
    'chat': null,
    'feedback': '/feedback',
    'rezepte': '/rezepte',
    'einstellungen': '/einstellungen',
    'abos': '/abos',
    'entdecken': '/entdecken',
    'kontakte': '/kontakte',
    'kalender': '/kalender',
    'reisen': '/reisen',
    'forum': '/forum',
  };

  /// In API-Daten dokumentierte englische Pfad-Präfixe → deutsche Routen.
  static const _englishPathPrefixes = <String, String>{
    '/calendar/': '/kalender/',
    '/trips/': '/reisen/',
    '/poll/': '/kalender/',
  };
}
