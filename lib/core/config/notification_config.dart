import 'package:flutter/material.dart';

import '../../features/notifications/models/notification_item.dart';

/// Übersetzt Benachrichtigungstypen in Titel, Text, Icon und Navigationsziel.
///
/// Vertrag (siehe `test/notification_config_test.dart` und die API-Doku
/// `doc/api/notifications/readme.md`): Die API liefert pro Benachrichtigung
/// nur `type` plus eine Relation-Liste in `data` — keine Titel, Texte oder
/// Routen. Diese Klasse bildet `type` und Relation-IDs rein lokal auf
/// deutsche Texte und Routen ab.
///
/// Aktuell unterstützter Typ: `forum_reply` (siehe API-Doku). Unbekannte
/// Typen liefern generische Standardwerte, `route` gibt dann `null` zurück
/// (Aufrufer öffnet die Inbox bzw. bis zu deren Umsetzung `/home`).
class NotificationTypeLabel {
  const NotificationTypeLabel._();

  /// Liefert die deutsche Route für eine Benachrichtigung, aufgebaut aus
  /// den Relation-IDs in [data]. `null`, wenn der Typ unbekannt ist oder
  /// Pflicht-Relationen fehlen.
  static String? route(String type, List<NotificationRelation> data) {
    return switch (type) {
      'forum_reply' => _forumReplyRoute(data),
      _ => null,
    };
  }

  /// Lokaler Titel für die Benachrichtigung.
  static String title(String type) {
    return switch (type) {
      'forum_reply' => 'Neue Antwort',
      _ => 'Neue Mitteilung',
    };
  }

  /// Generalisierter Anzeigetext, der ohne Nachladen weiterer Daten
  /// auskommt — Fallback, wenn die Anreicherung über die API scheitert.
  static String fallbackBody(String type) {
    return switch (type) {
      'forum_reply' => 'Jemand hat auf deinen Kommentar geantwortet',
      _ => 'Du hast eine neue Benachrichtigung.',
    };
  }

  /// Icon für die Benachrichtigung.
  static IconData icon(String type) {
    return switch (type) {
      'forum_reply' => Icons.forum_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  /// `/forum/{parent_forum}/beitrag/{parent_post}` — beide Relationen sind
  /// laut API-Doku Pflicht; ohne sie ist das Ziel nicht bestimmbar.
  static String? _forumReplyRoute(List<NotificationRelation> data) {
    final forumId = _identifierFor(data, 'parent_forum');
    final postId = _identifierFor(data, 'parent_post');
    if (forumId == null || postId == null) return null;
    return '/forum/$forumId/beitrag/$postId';
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
