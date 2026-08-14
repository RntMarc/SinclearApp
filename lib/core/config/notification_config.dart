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
/// Unterstützte Typen: `forum_reply`, `forum_comment` (siehe API-Doku).
/// Unbekannte Typen liefern generische Standardwerte, `route` gibt dann
/// `null` zurück (Aufrufer öffnet die Inbox bzw. bis zu deren Umsetzung
/// `/home`).
class NotificationTypeLabel {
  const NotificationTypeLabel._();

  /// Liefert die deutsche Route für eine Benachrichtigung, aufgebaut aus
  /// den Relation-IDs in [data]. `null`, wenn der Typ unbekannt ist oder
  /// Pflicht-Relationen fehlen.
  static String? route(String type, List<NotificationRelation> data) {
    return switch (type) {
      'forum_reply' || 'forum_comment' => _forumRoute(data),
      _ => null,
    };
  }

  /// Lokaler Fallback-Titel für die Benachrichtigung (spiegelt die
  /// API-generierten Titel, siehe API-Doku `notifications/types`).
  static String title(String type) {
    return switch (type) {
      'forum_reply' => 'Neue Antwort auf deinen Kommentar',
      'forum_comment' => 'Neuer Kommentar zu deinem Beitrag',
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
      _ => 'Du hast eine neue Benachrichtigung.',
    };
  }

  /// Icon für die Benachrichtigung.
  static IconData icon(String type) {
    return switch (type) {
      'forum_reply' || 'forum_comment' => Icons.forum_rounded,
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
