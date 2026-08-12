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

      expect(content.title, 'Neue Antwort');
      expect(
        content.body,
        'Tom hat auf deinen Kommentar unter dem Post „BLABLABLA“ geantwortet',
      );
      expect(content.route, '/forum/f1/beitrag/p1');
    });

    test('generalisierter Text, wenn das Nachladen komplett scheitert', () async {
      final content = await resolver.resolve(_forumReplyItem());

      expect(content.title, 'Neue Antwort');
      expect(content.body, 'Jemand hat auf deinen Kommentar geantwortet');
      expect(content.route, '/forum/f1/beitrag/p1');
    });

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

      expect(content.body, 'Jemand hat auf deinen Kommentar geantwortet');
      expect(content.route, isNull);
    });
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
