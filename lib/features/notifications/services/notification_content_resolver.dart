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

/// Erzeugt aus einer rohen [NotificationItem] (nur `type` + Relation-IDs)
/// den anzuzeigenden Inhalt.
///
/// Ablauf pro Benachrichtigung:
/// 1. Typ erkennen und Relation-IDs aus `data` interpretieren.
/// 2. Deep-Link lokal aus den IDs aufbauen (siehe [NotificationTypeLabel]).
/// 3. Referenzierte Ressourcen von der API nachladen und daraus den
///    vollständigen Text generieren (z. B. „Tom hat auf deinen Kommentar
///    unter dem Post „X“ geantwortet“).
/// 4. Schlägt das Nachladen fehl (offline, gelöschtes Objekt, …), wird auf
///    den generalisierten Text von [NotificationTypeLabel.fallbackBody]
///    zurückgefallen (z. B. „Jemand hat auf deinen Kommentar geantwortet“).
///
/// Die API liefert bewusst keine Titel, Texte oder Routen — diese Klasse
/// ist die einzige Stelle, die sie clientseitig erzeugt. Neue
/// Benachrichtigungstypen werden hier (Anreicherung) und in
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
    if (item.type == 'forum_reply') {
      return _resolveForumReply(item, route);
    }
    return ResolvedNotificationContent(
      title: NotificationTypeLabel.title(item.type),
      body: NotificationTypeLabel.fallbackBody(item.type),
      route: route,
    );
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
