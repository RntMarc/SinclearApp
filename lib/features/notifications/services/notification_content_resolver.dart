// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:developer' as developer;

import '../../../core/config/notification_config.dart';
import '../../../core/notifications/local_notification_helper.dart';
import '../../forum/services/forum_service.dart';
import '../../user/services/user_service.dart';
import '../models/notification_item.dart';

/// Stabile, nicht-negative Android-Notification-ID, abgeleitet aus der
/// Notification-UUID (Android akzeptiert nur ints >= 0).
int localNotificationId(String id) => id.hashCode & 0x7fffffff;

/// Vollständig aufbereiteter Inhalt einer Benachrichtigung: bereit zur
/// Anzeige und zur Navigation. [route] ist `null`, wenn kein Ziel bestimmt
/// werden kann (Aufrufer nutzt dann den Inbox- bzw. `/home`-Fallback).
class ResolvedNotificationContent {
  final String title;
  final String body;
  final String? route;

  const ResolvedNotificationContent({
    required this.title,
    required this.body,
    required this.route,
  });
}

/// Bereitet eine rohe [NotificationItem] für die Anzeige auf.
///
/// Ablauf pro Benachrichtigung:
/// 1. Liefert die API `title` und `text` mit (Regelfall), werden sie direkt
///    verwendet — kein Extra-Aufruf gegen die API.
/// 2. Fehlen sie, erzeugt der Client den Inhalt lokal: Deep-Link aus den
///    Relation-IDs (siehe [NotificationTypeLabel]) und Anzeigetext durch
///    Nachladen der referenzierten Ressourcen (z. B. „Tom hat auf deinen
///    Kommentar unter dem Post „X“ geantwortet“).
/// 3. Schlägt das Nachladen fehl (offline, gelöschtes Objekt, …), greifen
///    die generalisierten Texte von [NotificationTypeLabel] (Fallback).
///
/// Neue Benachrichtigungstypen werden hier (lokale Anreicherung) und in
/// [NotificationTypeLabel] (Fallback-Texte, Icon, Route) ergänzt.
class NotificationContentResolver {
  final UserService _user;
  final ForumService _forum;

  NotificationContentResolver({
    required UserService user,
    required ForumService forum,
  }) : _user = user,
       _forum = forum;

  /// Bereitet [item] vollständig auf. Wirft nie — bei Fehlern wird auf
  /// die generalisierten Fallback-Texte zurückgefallen.
  Future<ResolvedNotificationContent> resolve(NotificationItem item) async {
    final route = NotificationTypeLabel.route(item.type, item.data);
    if (item.hasApiContent) {
      return ResolvedNotificationContent(
        title: item.title!,
        body: item.text!,
        route: route,
      );
    }
    return switch (item.type) {
      'forum_reply' => _resolveForumReply(item, route),
      'forum_comment' => _resolveForumComment(item, route),
      'story_post' => _resolveStoryPost(item, route),
      _ => _fallback(item.type, route),
    };
  }

  /// Zeigt die Benachrichtigung als lokale System-Benachrichtigung an.
  ///
  /// Das Tap-Payload enthält die komplette Benachrichtigung als JSON,
  /// damit der Tap-Handler daraus Zielroute und `markRead`-ID
  /// rekonstruieren kann.
  Future<void> showLocal(NotificationItem item) async {
    try {
      final content = await resolve(item);
      await LocalNotificationHelper.show(
        id: localNotificationId(item.id),
        title: content.title,
        body: content.body,
        payload: jsonEncode(item.toJson()),
      );
    } catch (e, st) {
      developer.log(
        'Lokale Anzeige der Benachrichtigung fehlgeschlagen',
        error: e,
        stackTrace: st,
        name: 'notification_content',
      );
    }
  }

  /// `forum_reply`: „{Autor} hat auf deinen Kommentar unter dem Post
  /// „{Post}“ geantwortet“ — Autor und Post-Text werden nachgeladen,
  /// fehlende Teile fallen auf die generalisierte Form zurück.
  Future<ResolvedNotificationContent> _resolveForumReply(
    NotificationItem item,
    String? route,
  ) async {
    final authorId = item.identifierFor('reply_author');
    final forumId = item.identifierFor('parent_forum');
    final postId = item.identifierFor('parent_post');

    final results = await Future.wait([
      _attempt('reply_author', () async {
        if (authorId == null) return null;
        return (await _user.get(authorId)).base.displayName;
      }),
      _attempt('parent_post', () async {
        if (forumId == null || postId == null) return null;
        return (await _forum.getPost(forumId, postId)).text;
      }),
    ]);

    final authorName = results[0];
    final postSnippet = switch (results[1]) {
      final text? => _snippet(text),
      null => null,
    };

    // Nichts nachladbar: generalisierter Fallback-Text (identisch mit der
    // API-Formulierung), statt einer selbst zusammengesetzten Variante.
    if (authorName == null && postSnippet == null) {
      return _fallback(item.type, route);
    }

    final author = authorName == null || authorName.isEmpty
        ? 'Jemand'
        : authorName;
    final postPart = postSnippet == null
        ? ''
        : ' unter dem Post „$postSnippet“';

    return ResolvedNotificationContent(
      title: NotificationTypeLabel.title(item.type),
      body: '$author hat auf deinen Kommentar$postPart geantwortet',
      route: route,
    );
  }

  /// `forum_comment`: „{Autor} hat deinen Beitrag kommentiert“ — der Autor
  /// wird nachgeladen; schlägt das fehl, greift der generalisierte
  /// Fallback-Text.
  Future<ResolvedNotificationContent> _resolveForumComment(
    NotificationItem item,
    String? route,
  ) async {
    final authorId = item.identifierFor('comment_author');
    final authorName = await _attempt('comment_author', () async {
      if (authorId == null) return null;
      return (await _user.get(authorId)).base.displayName;
    });

    if (authorName == null || authorName.isEmpty) {
      return _fallback(item.type, route);
    }

    return ResolvedNotificationContent(
      title: NotificationTypeLabel.title(item.type),
      body: '$authorName hat deinen Beitrag kommentiert',
      route: route,
    );
  }

  /// `story_post`: „{Autor} hat eine neue Story veröffentlicht“ — der Autor
  /// wird nachgeladen; schlägt das fehl, greift der generalisierte
  /// Fallback-Text.
  Future<ResolvedNotificationContent> _resolveStoryPost(
    NotificationItem item,
    String? route,
  ) async {
    final authorId = item.identifierFor('story_author');
    final authorName = await _attempt('story_author', () async {
      if (authorId == null) return null;
      return (await _user.get(authorId)).base.displayName;
    });

    if (authorName == null || authorName.isEmpty) {
      return _fallback(item.type, route);
    }

    return ResolvedNotificationContent(
      title: NotificationTypeLabel.title(item.type),
      body: '$authorName hat eine neue Story veröffentlicht',
      route: route,
    );
  }

  /// Generalisierter Fallback für unbekannte Typen.
  ResolvedNotificationContent _fallback(String type, String? route) {
    return ResolvedNotificationContent(
      title: NotificationTypeLabel.title(type),
      body: NotificationTypeLabel.fallbackBody(type),
      route: route,
    );
  }

  /// Kürzt Post-Texte für die einzeilige Benachrichtigungsanzeige.
  static String? _snippet(String text) {
    final collapsed = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) return null;
    const max = 80;
    return collapsed.length <= max
        ? collapsed
        : '${collapsed.substring(0, max)}…';
  }

  /// Führt [task] aus und liefert bei Fehlern `null` — die Anzeige darf
  /// an einem fehlgeschlagenen Nachlade-Schritt nicht scheitern.
  Future<T?> _attempt<T>(String label, Future<T?> Function() task) async {
    try {
      return await task();
    } catch (e, st) {
      developer.log(
        'Nachladen von $label fehlgeschlagen',
        error: e,
        stackTrace: st,
        name: 'notification_content',
      );
      return null;
    }
  }
}
