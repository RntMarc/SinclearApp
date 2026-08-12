import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/config/notification_config.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_item.dart';

void main() {
  /// Relation-Liste exakt so, wie die API sie für `forum_reply` liefert.
  const forumReplyData = [
    NotificationRelation(
      relation: 'reply_author',
      object: 'User',
      identifier: 'user-reply',
    ),
    NotificationRelation(
      relation: 'comment_author',
      object: 'User',
      identifier: 'user-comment',
    ),
    NotificationRelation(
      relation: 'post_author',
      object: 'User',
      identifier: 'user-post',
    ),
    NotificationRelation(
      relation: 'parent_comment',
      object: 'ForumPostComment',
      identifier: 'c1',
    ),
    NotificationRelation(
      relation: 'parent_post',
      object: 'ForumPost',
      identifier: 'p1',
    ),
    NotificationRelation(
      relation: 'parent_forum',
      object: 'Forum',
      identifier: 'f1',
    ),
  ];

  group('NotificationTypeLabel.route', () {
    test('forum_reply navigiert zum Beitrag (/forum/{f}/beitrag/{p})', () {
      expect(
        NotificationTypeLabel.route('forum_reply', forumReplyData),
        '/forum/f1/beitrag/p1',
      );
    });

    test('forum_reply ohne parent_forum oder parent_post gibt null', () {
      final ohneForum = forumReplyData
          .where((e) => e.relation != 'parent_forum')
          .toList();
      final ohnePost = forumReplyData
          .where((e) => e.relation != 'parent_post')
          .toList();

      expect(NotificationTypeLabel.route('forum_reply', ohneForum), isNull);
      expect(NotificationTypeLabel.route('forum_reply', ohnePost), isNull);
      expect(NotificationTypeLabel.route('forum_reply', const []), isNull);
    });

    test('unbekannte Typen geben null (Inbox-Fallback)', () {
      expect(NotificationTypeLabel.route('unbekannt', forumReplyData), isNull);
      expect(NotificationTypeLabel.route('', const []), isNull);
    });
  });

  group('NotificationTypeLabel Fallback-Rendering', () {
    test('forum_reply rendert Titel, generalisierten Text und Icon', () {
      expect(NotificationTypeLabel.title('forum_reply'), 'Neue Antwort');
      expect(
        NotificationTypeLabel.fallbackBody('forum_reply'),
        'Jemand hat auf deinen Kommentar geantwortet',
      );
      expect(NotificationTypeLabel.icon('forum_reply'), Icons.forum_rounded);
    });

    test('unbekannte Typen rendern generische Standardwerte', () {
      expect(NotificationTypeLabel.title('unbekannt'), 'Neue Mitteilung');
      expect(NotificationTypeLabel.fallbackBody('unbekannt'), isNotEmpty);
      expect(
        NotificationTypeLabel.icon('unbekannt'),
        Icons.notifications_rounded,
      );
    });
  });
}
