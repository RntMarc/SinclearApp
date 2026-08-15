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

  /// Relation-Liste exakt so, wie die API sie für `forum_comment` liefert
  /// (bewusst ohne `parent_comment` und `reply_author`).
  const forumCommentData = [
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

  /// Relation-Liste exakt so, wie die API sie für `story_post` liefert.
  const storyPostData = [
    NotificationRelation(
      relation: 'story_author',
      object: 'User',
      identifier: 'user-story',
    ),
    NotificationRelation(relation: 'story', object: 'Story', identifier: 's1'),
  ];

  group('NotificationTypeLabel.route', () {
    test('forum_reply navigiert zum Beitrag (/forum/{f}/beitrag/{p})', () {
      expect(
        NotificationTypeLabel.route('forum_reply', forumReplyData),
        '/forum/f1/beitrag/p1',
      );
    });

    test('forum_comment navigiert zum Beitrag (/forum/{f}/beitrag/{p})', () {
      expect(
        NotificationTypeLabel.route('forum_comment', forumCommentData),
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

    test('forum_comment ohne parent_forum oder parent_post gibt null', () {
      final ohneForum = forumCommentData
          .where((e) => e.relation != 'parent_forum')
          .toList();
      final ohnePost = forumCommentData
          .where((e) => e.relation != 'parent_post')
          .toList();

      expect(NotificationTypeLabel.route('forum_comment', ohneForum), isNull);
      expect(NotificationTypeLabel.route('forum_comment', ohnePost), isNull);
    });

    test('story_post navigiert zur Story (/stories/{s})', () {
      expect(
        NotificationTypeLabel.route('story_post', storyPostData),
        '/stories/s1',
      );
    });

    test('story_post ohne story Relation gibt null', () {
      final ohneStory = storyPostData
          .where((e) => e.relation != 'story')
          .toList();

      expect(NotificationTypeLabel.route('story_post', ohneStory), isNull);
      expect(NotificationTypeLabel.route('story_post', const []), isNull);
    });

    test('unbekannte Typen geben null (Inbox-Fallback)', () {
      expect(NotificationTypeLabel.route('unbekannt', forumReplyData), isNull);
      expect(NotificationTypeLabel.route('', const []), isNull);
    });
  });

  group('NotificationTypeLabel Fallback-Rendering', () {
    test('forum_reply rendert Titel, generalisierten Text und Icon', () {
      expect(
        NotificationTypeLabel.title('forum_reply'),
        'Neue Antwort auf deinen Kommentar',
      );
      expect(
        NotificationTypeLabel.fallbackBody('forum_reply'),
        'Jemand hat auf deinen Kommentar geantwortet.',
      );
      expect(NotificationTypeLabel.icon('forum_reply'), Icons.forum_rounded);
    });

    test('forum_comment rendert Titel, generalisierten Text und Icon', () {
      expect(
        NotificationTypeLabel.title('forum_comment'),
        'Neuer Kommentar zu deinem Beitrag',
      );
      expect(
        NotificationTypeLabel.fallbackBody('forum_comment'),
        'Jemand hat deinen Beitrag kommentiert.',
      );
      expect(NotificationTypeLabel.icon('forum_comment'), Icons.forum_rounded);
    });

    test('story_post rendert Titel, generalisierten Text und Icon', () {
      expect(NotificationTypeLabel.title('story_post'), 'Neue Story');
      expect(
        NotificationTypeLabel.fallbackBody('story_post'),
        'Jemand hat eine neue Story veröffentlicht.',
      );
      expect(
        NotificationTypeLabel.icon('story_post'),
        Icons.auto_stories_rounded,
      );
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
