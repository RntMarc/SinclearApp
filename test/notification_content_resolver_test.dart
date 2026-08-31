import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';
import 'package:sinclear_beyond/features/forum/models/forum_models.dart';
import 'package:sinclear_beyond/features/forum/services/forum_service.dart';
import 'package:sinclear_beyond/features/notifications/models/notification_item.dart';
import 'package:sinclear_beyond/features/notifications/services/notification_content_resolver.dart';
import 'package:sinclear_beyond/features/user/models/user_models.dart';
import 'package:sinclear_beyond/features/user/services/user_service.dart';

ApiClient _dummyApi() => ApiClient(baseUrl: 'http://localhost');
AuthService _dummyAuth() =>
    AuthService(api: _dummyApi(), storage: TokenStorage());

/// Liefert [displayName], oder wirft, wenn es `null` ist (simuliert
/// Offline/API-Fehler beim Nachladen).
class _FakeUserService extends UserService {
  _FakeUserService() : super(api: _dummyApi(), auth: _dummyAuth());

  String? displayName;

  @override
  Future<UserDetailPublic> get(String userId) async {
    final name = displayName;
    if (name == null) throw Exception('Nachladen fehlgeschlagen');
    return UserDetailPublic(
      base: UserBasePublic(
        id: userId,
        displayName: name,
        isAdmin: false,
        createdAt: '2026-01-01 00:00:00',
        onboardingCompleted: true,
      ),
    );
  }
}

/// Liefert einen Post mit [postText], oder wirft bei `null`.
class _FakeForumService extends ForumService {
  _FakeForumService() : super(api: _dummyApi(), auth: _dummyAuth());

  String? postText;

  @override
  Future<FeedPost> getPost(String forumId, String postId) async {
    final text = postText;
    if (text == null) throw Exception('Nachladen fehlgeschlagen');
    return FeedPost(
      id: postId,
      forumId: forumId,
      userId: 'user-post',
      type: 'text',
      content: {'text': text},
      upvoteCount: 0,
      commentCount: 0,
      hasVoted: false,
      createdAt: '2026-01-01 00:00:00',
      updatedAt: '2026-01-01 00:00:00',
    );
  }
}

NotificationItem _forumReplyItem() => NotificationItem(
  id: 'n1',
  type: 'forum_reply',
  createdAt: DateTime.utc(2026, 8, 10, 14, 30),
  data: const [
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
  ],
);

NotificationItem _forumCommentItem() => NotificationItem(
  id: 'n2',
  type: 'forum_comment',
  createdAt: DateTime.utc(2026, 8, 10, 14, 30),
  data: const [
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
  ],
);

NotificationItem _forumPostItem() => NotificationItem(
  id: 'n9',
  type: 'forum_post',
  createdAt: DateTime.utc(2026, 8, 10, 14, 30),
  data: const [
    NotificationRelation(
      relation: 'post_author',
      object: 'User',
      identifier: 'user-author',
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
  ],
);

NotificationItem _forumUpvoteItem() => NotificationItem(
  id: 'n10',
  type: 'forum_upvote',
  createdAt: DateTime.utc(2026, 8, 10, 14, 30),
  data: const [
    NotificationRelation(
      relation: 'voter',
      object: 'User',
      identifier: 'user-voter',
    ),
    NotificationRelation(
      relation: 'post_author',
      object: 'User',
      identifier: 'user-author',
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
  ],
);

NotificationItem _storyPostItem() => NotificationItem(
  id: 'n3',
  type: 'story_post',
  createdAt: DateTime.utc(2026, 8, 10, 14, 30),
  data: const [
    NotificationRelation(
      relation: 'story_author',
      object: 'User',
      identifier: 'user-story',
    ),
    NotificationRelation(relation: 'story', object: 'Story', identifier: 's1'),
  ],
);

NotificationItem _directMessageItem() => NotificationItem(
  id: 'n7',
  type: 'direct_message',
  createdAt: DateTime.utc(2026, 8, 10, 14, 30),
  data: const [
    NotificationRelation(
      relation: 'sender',
      object: 'User',
      identifier: 'user-sender',
    ),
    NotificationRelation(
      relation: 'conversation',
      object: 'ChatConversation',
      identifier: 'conv1',
    ),
  ],
);

void main() {
  late _FakeUserService user;
  late _FakeForumService forum;
  late NotificationContentResolver resolver;

  setUp(() {
    user = _FakeUserService();
    forum = _FakeForumService();
    resolver = NotificationContentResolver(user: user, forum: forum);
  });

  group('forum_reply', () {
    test('voller Text, wenn Autor und Post geladen werden können', () async {
      user.displayName = 'Tom';
      forum.postText = 'BLABLABLA';

      final content = await resolver.resolve(_forumReplyItem());

      expect(content.title, 'Neue Antwort auf deinen Kommentar');
      expect(
        content.body,
        'Tom hat auf deinen Kommentar unter dem Post „BLABLABLA“ geantwortet',
      );
      expect(content.route, '/forum/f1/beitrag/p1');
    });

    test(
      'generalisierter Text, wenn das Nachladen komplett scheitert',
      () async {
        final content = await resolver.resolve(_forumReplyItem());

        expect(content.title, 'Neue Antwort auf deinen Kommentar');
        expect(content.body, 'Jemand hat auf deinen Kommentar geantwortet.');
        expect(content.route, '/forum/f1/beitrag/p1');
      },
    );

    test('nur Autor ladbar: Text ohne Post-Teil', () async {
      user.displayName = 'Tom';

      final content = await resolver.resolve(_forumReplyItem());

      expect(content.body, 'Tom hat auf deinen Kommentar geantwortet');
    });

    test('nur Post ladbar: Text mit „Jemand“', () async {
      forum.postText = 'BLABLABLA';

      final content = await resolver.resolve(_forumReplyItem());

      expect(
        content.body,
        'Jemand hat auf deinen Kommentar unter dem Post „BLABLABLA“ geantwortet',
      );
    });

    test('Post-Text wird für die Anzeige gekürzt', () async {
      forum.postText = 'x' * 100;

      final content = await resolver.resolve(_forumReplyItem());

      expect(content.body, contains('${'x' * 80}…'));
      expect(content.body, isNot(contains('x' * 81)));
    });

    test('Zeilenumbrüche im Post-Text werden normalisiert', () async {
      forum.postText = 'Zeile eins\n\nZeile   zwei';

      final content = await resolver.resolve(_forumReplyItem());

      expect(content.body, contains('„Zeile eins Zeile zwei“'));
    });

    test('Post ohne Text (z. B. Musik-Post): kein Post-Teil', () async {
      user.displayName = 'Tom';
      forum.postText = '   ';

      final content = await resolver.resolve(_forumReplyItem());

      expect(content.body, 'Tom hat auf deinen Kommentar geantwortet');
    });

    test('fehlende Relationen: generalisierter Text, Route null', () async {
      final item = NotificationItem(
        id: 'n2',
        type: 'forum_reply',
        createdAt: DateTime.utc(2026, 8, 10, 14, 30),
      );

      final content = await resolver.resolve(item);

      expect(content.body, 'Jemand hat auf deinen Kommentar geantwortet.');
      expect(content.route, isNull);
    });
  });

  group('forum_comment', () {
    test('voller Text, wenn der Autor geladen werden kann', () async {
      user.displayName = 'Tom';

      final content = await resolver.resolve(_forumCommentItem());

      expect(content.title, 'Neuer Kommentar zu deinem Beitrag');
      expect(content.body, 'Tom hat deinen Beitrag kommentiert');
      expect(content.route, '/forum/f1/beitrag/p1');
    });

    test('generalisierter Text, wenn das Nachladen scheitert', () async {
      final content = await resolver.resolve(_forumCommentItem());

      expect(content.title, 'Neuer Kommentar zu deinem Beitrag');
      expect(content.body, 'Jemand hat deinen Beitrag kommentiert.');
      expect(content.route, '/forum/f1/beitrag/p1');
    });

    test('fehlende Relationen: generalisierter Text, Route null', () async {
      final item = NotificationItem(
        id: 'n4',
        type: 'forum_comment',
        createdAt: DateTime.utc(2026, 8, 10, 14, 30),
      );

      final content = await resolver.resolve(item);

      expect(content.body, 'Jemand hat deinen Beitrag kommentiert.');
      expect(content.route, isNull);
    });
  });

  group('forum_post', () {
    test('voller Text, wenn der Autor geladen werden kann', () async {
      user.displayName = 'Maria';

      final content = await resolver.resolve(_forumPostItem());

      expect(content.title, 'Neuer Beitrag im Forum');
      expect(
        content.body,
        'Maria hat einen neuen Beitrag im Forum veröffentlicht',
      );
      expect(content.route, '/forum/f1/beitrag/p1');
    });

    test('generalisierter Text, wenn das Nachladen scheitert', () async {
      final content = await resolver.resolve(_forumPostItem());

      expect(content.title, 'Neuer Beitrag im Forum');
      expect(
        content.body,
        'Jemand hat einen neuen Beitrag im Forum veröffentlicht.',
      );
      expect(content.route, '/forum/f1/beitrag/p1');
    });

    test('fehlende Relationen: generalisierter Text, Route null', () async {
      final item = NotificationItem(
        id: 'n11',
        type: 'forum_post',
        createdAt: DateTime.utc(2026, 8, 10, 14, 30),
      );

      final content = await resolver.resolve(item);

      expect(
        content.body,
        'Jemand hat einen neuen Beitrag im Forum veröffentlicht.',
      );
      expect(content.route, isNull);
    });
  });

  group('forum_upvote', () {
    test('voller Text, wenn Voter und Post geladen werden können', () async {
      user.displayName = 'Tom';
      forum.postText = 'Toller Beitrag';

      final content = await resolver.resolve(_forumUpvoteItem());

      expect(content.title, 'Neue Bewertung');
      expect(
        content.body,
        'Tom hat deinen Beitrag \u201eToller Beitrag\u201c positiv bewertet',
      );
      expect(content.route, '/forum/f1/beitrag/p1');
    });

    test(
      'generalisierter Text, wenn das Nachladen komplett scheitert',
      () async {
        final content = await resolver.resolve(_forumUpvoteItem());

        expect(content.title, 'Neue Bewertung');
        expect(
          content.body,
          'Jemand hat deinen Beitrag positiv bewertet.',
        );
        expect(content.route, '/forum/f1/beitrag/p1');
      },
    );

    test('nur Voter ladbar: Text ohne Post-Teil', () async {
      user.displayName = 'Tom';

      final content = await resolver.resolve(_forumUpvoteItem());

      expect(content.body, 'Tom hat deinen Beitrag positiv bewertet');
    });

    test('nur Post ladbar: Text mit „Jemand"', () async {
      forum.postText = 'Toller Beitrag';

      final content = await resolver.resolve(_forumUpvoteItem());

      expect(
        content.body,
        'Jemand hat deinen Beitrag \u201eToller Beitrag\u201c positiv bewertet',
      );
    });

    test('Post-Text wird für die Anzeige gekürzt', () async {
      forum.postText = 'x' * 100;

      final content = await resolver.resolve(_forumUpvoteItem());

      expect(content.body, contains('${'x' * 80}\u2026'));
      expect(content.body, isNot(contains('x' * 81)));
    });

    test('Post ohne Text (z. B. Musik-Post): kein Post-Teil', () async {
      user.displayName = 'Tom';
      forum.postText = '   ';

      final content = await resolver.resolve(_forumUpvoteItem());

      expect(content.body, 'Tom hat deinen Beitrag positiv bewertet');
    });

    test('fehlende Relationen: generalisierter Text, Route null', () async {
      final item = NotificationItem(
        id: 'n12',
        type: 'forum_upvote',
        createdAt: DateTime.utc(2026, 8, 10, 14, 30),
      );

      final content = await resolver.resolve(item);

      expect(content.body, 'Jemand hat deinen Beitrag positiv bewertet.');
      expect(content.route, isNull);
    });
  });

  group('story_post', () {
    test('voller Text, wenn der Autor geladen werden kann', () async {
      user.displayName = 'Anna';

      final content = await resolver.resolve(_storyPostItem());

      expect(content.title, 'Neue Story');
      expect(content.body, 'Anna hat eine neue Story veröffentlicht');
      expect(content.route, '/stories/s1');
    });

    test('generalisierter Text, wenn das Nachladen scheitert', () async {
      final content = await resolver.resolve(_storyPostItem());

      expect(content.title, 'Neue Story');
      expect(content.body, 'Jemand hat eine neue Story veröffentlicht.');
      expect(content.route, '/stories/s1');
    });

    test('fehlende Relationen: generalisierter Text, Route null', () async {
      final item = NotificationItem(
        id: 'n5',
        type: 'story_post',
        createdAt: DateTime.utc(2026, 8, 10, 14, 30),
      );

      final content = await resolver.resolve(item);

      expect(content.body, 'Jemand hat eine neue Story veröffentlicht.');
      expect(content.route, isNull);
    });
  });

  group('direct_message', () {
    test('voller Text, wenn der Absender geladen werden kann', () async {
      user.displayName = 'Tom';

      final content = await resolver.resolve(_directMessageItem());

      expect(content.title, 'Neue Nachricht');
      expect(content.body, 'Tom hat dir geschrieben');
      expect(content.route, '/chat/conv1');
    });

    test('generalisierter Text, wenn das Nachladen scheitert', () async {
      final content = await resolver.resolve(_directMessageItem());

      expect(content.title, 'Neue Nachricht');
      expect(content.body, 'Du hast eine neue Nachricht.');
      expect(content.route, '/chat/conv1');
    });

    test('fehlende Relationen: generalisierter Text, Route null', () async {
      final item = NotificationItem(
        id: 'n8',
        type: 'direct_message',
        createdAt: DateTime.utc(2026, 8, 10, 14, 30),
      );

      final content = await resolver.resolve(item);

      expect(content.body, 'Du hast eine neue Nachricht.');
      expect(content.route, isNull);
    });
  });

  group('API-gelieferte Titel und Texte', () {
    test('werden direkt verwendet, ohne Nachladen', () async {
      final item = NotificationItem(
        id: 'n5',
        type: 'forum_reply',
        title: 'Titel von der API',
        text: 'Text von der API',
        createdAt: DateTime.utc(2026, 8, 10, 14, 30),
        data: const [
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
        ],
      );

      final content = await resolver.resolve(item);

      expect(content.title, 'Titel von der API');
      expect(content.body, 'Text von der API');
      expect(content.route, '/forum/f1/beitrag/p1');
    });

    test('gelten auch für unbekannte Typen (Route bleibt null)', () async {
      final item = NotificationItem(
        id: 'n6',
        type: 'irgendwas_neues',
        title: 'Titel von der API',
        text: 'Text von der API',
        createdAt: DateTime.utc(2026, 8, 10, 14, 30),
      );

      final content = await resolver.resolve(item);

      expect(content.title, 'Titel von der API');
      expect(content.body, 'Text von der API');
      expect(content.route, isNull);
    });

    test(
      'unvollständig (nur Titel): lokale Generierung als Fallback',
      () async {
        user.displayName = 'Tom';

        final item = NotificationItem(
          id: 'n7',
          type: 'forum_reply',
          title: 'Nur ein Titel',
          createdAt: DateTime.utc(2026, 8, 10, 14, 30),
          data: _forumReplyItem().data,
        );

        final content = await resolver.resolve(item);

        expect(content.title, 'Neue Antwort auf deinen Kommentar');
        expect(content.body, 'Tom hat auf deinen Kommentar geantwortet');
      },
    );
  });

  group('unbekannte Typen', () {
    test('generische Werte ohne API-Zugriff', () async {
      final item = NotificationItem(
        id: 'n3',
        type: 'irgendwas_neues',
        createdAt: DateTime.utc(2026, 8, 10, 14, 30),
      );

      final content = await resolver.resolve(item);

      expect(content.title, 'Neue Mitteilung');
      expect(content.body, 'Du hast eine neue Benachrichtigung.');
      expect(content.route, isNull);
    });
  });

  group('localNotificationId', () {
    test('liefert nicht-negative IDs für UUIDs', () {
      const ids = [
        '01923456-7890-7abc-def0-123456789012',
        '00000000-0000-0000-0000-000000000000',
        'abc-xyz',
      ];
      for (final id in ids) {
        expect(localNotificationId(id), greaterThanOrEqualTo(0));
      }
    });
  });
}
