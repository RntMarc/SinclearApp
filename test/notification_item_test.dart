import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_item.dart';

void main() {
  final forumReplyJson = {
    'id': '01923456-7890-7abc-def0-123456789012',
    'userId': 'user-comment',
    'type': 'forum_reply',
    'title': 'Neue Antwort auf deinen Kommentar',
    'text': 'Jemand hat auf deinen Kommentar geantwortet.',
    'data': [
      {
        'relation': 'reply_author',
        'object': 'User',
        'identifier': 'user-reply',
      },
      {
        'relation': 'comment_author',
        'object': 'User',
        'identifier': 'user-comment',
      },
      {'relation': 'post_author', 'object': 'User', 'identifier': 'user-post'},
      {
        'relation': 'parent_comment',
        'object': 'ForumPostComment',
        'identifier': 'comment-id',
      },
      {
        'relation': 'parent_post',
        'object': 'ForumPost',
        'identifier': 'post-id',
      },
      {'relation': 'parent_forum', 'object': 'Forum', 'identifier': 'forum-id'},
    ],
    'isRead': false,
    'createdAt': '2026-08-10 14:30:00',
  };

  group('NotificationItem.fromJson', () {
    test('parst den forum_reply-Vertrag der API vollständig', () {
      final item = NotificationItem.fromJson(forumReplyJson);

      expect(item.id, '01923456-7890-7abc-def0-123456789012');
      expect(item.type, 'forum_reply');
      expect(item.title, 'Neue Antwort auf deinen Kommentar');
      expect(item.text, 'Jemand hat auf deinen Kommentar geantwortet.');
      expect(item.hasApiContent, isTrue);
      expect(item.data, hasLength(6));
      expect(item.data.first.relation, 'reply_author');
      expect(item.data.first.object, 'User');
      expect(item.data.first.identifier, 'user-reply');
      expect(item.isRead, isFalse);
      expect(item.createdAt.toUtc(), DateTime.utc(2026, 8, 10, 14, 30, 0));
    });

    test('isRead wird auch als int akzeptiert', () {
      final item = NotificationItem.fromJson({...forumReplyJson, 'isRead': 1});
      expect(item.isRead, isTrue);
    });

    test('fehlende oder leere title/text ergeben hasApiContent == false', () {
      for (final raw in [
        {'title': null, 'text': null},
        {'title': '', 'text': ''},
        {'title': 'Titel', 'text': ''},
      ]) {
        final item = NotificationItem.fromJson({...forumReplyJson, ...raw});
        expect(item.hasApiContent, isFalse);
      }
    });

    test('fehlende oder ungültige data-Liste wird zu leerer Liste', () {
      for (final raw in [null, {}, 'kaputt']) {
        final item = NotificationItem.fromJson({
          'id': 'id',
          'type': 'forum_reply',
          'data': raw,
          'createdAt': '2026-08-10 14:30:00',
        });
        expect(item.data, isEmpty);
      }
    });

    test('Push-Payload ohne userId/isRead ist parsebar', () {
      final item = NotificationItem.fromJson({
        'id': 'push-id',
        'type': 'forum_reply',
        'data': forumReplyJson['data'],
        'createdAt': '2026-08-10 14:30:00.000',
      });

      expect(item.id, 'push-id');
      expect(item.isRead, isFalse);
      expect(item.title, isNull);
      expect(item.text, isNull);
      expect(item.data, hasLength(6));
    });
  });

  group('NotificationItem.identifierFor', () {
    test('liefert die ID zur gesuchten Relation', () {
      final item = NotificationItem.fromJson(forumReplyJson);

      expect(item.identifierFor('reply_author'), 'user-reply');
      expect(item.identifierFor('parent_forum'), 'forum-id');
      expect(item.identifierFor('parent_post'), 'post-id');
      expect(item.identifierFor('parent_comment'), 'comment-id');
    });

    test('liefert null für unbekannte Relationen', () {
      final item = NotificationItem.fromJson(forumReplyJson);

      expect(item.identifierFor('gibts_nicht'), isNull);
    });

    test('ignoriert Einträge mit leerer ID', () {
      final item = NotificationItem.fromJson({
        'id': 'id',
        'type': 'forum_reply',
        'data': [
          {'relation': 'parent_forum', 'object': 'Forum', 'identifier': ''},
        ],
        'createdAt': '2026-08-10 14:30:00',
      });

      expect(item.identifierFor('parent_forum'), isNull);
    });
  });

  group('NotificationItem.toJson', () {
    test('Round-Trip über JSON rekonstruiert die Benachrichtigung', () {
      final original = NotificationItem.fromJson(forumReplyJson);

      final restored = NotificationItem.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.title, original.title);
      expect(restored.text, original.text);
      expect(
        restored.data.map((e) => e.toJson()).toList(),
        original.data.map((e) => e.toJson()).toList(),
      );
      expect(restored.createdAt, original.createdAt);
    });
  });
}
