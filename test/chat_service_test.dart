import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';
import 'package:sinclear_beyond/features/chat/services/chat_service.dart';

class _MockApiClient extends ApiClient {
  final List<Map<String, dynamic>> responses = [];
  final List<String> calledPaths = [];
  final List<Map<String, String?>?> calledQueryParams = [];
  final List<Map<String, dynamic>?> calledBodies = [];

  _MockApiClient() : super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    calledPaths.add(path);
    calledQueryParams.add(queryParams);
    if (responses.isNotEmpty) return responses.removeAt(0);
    return {'data': <Map<String, dynamic>>[]};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    calledPaths.add(path);
    calledBodies.add(body);
    if (responses.isNotEmpty) return responses.removeAt(0);
    return {'data': {}};
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    calledPaths.add(path);
    calledBodies.add(body);
    if (responses.isNotEmpty) return responses.removeAt(0);
    return {'data': {}};
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
    bool parseResponse = false,
  }) async {
    calledPaths.add(path);
    calledBodies.add(body);
    if (responses.isNotEmpty) return responses.removeAt(0);
    return {};
  }
}

class _FakeAuth extends AuthService {
  _FakeAuth(ApiClient api) : super(api: api, storage: TokenStorage());

  @override
  Future<String> getAccessToken() async => 'test-token';
}

Map<String, dynamic> _conversationJson(
  String id, {
  int unread = 0,
  String lastContent = 'Hallo',
  String updatedAt = '2026-08-16 10:00:00',
  int lastReadSeq = 0,
}) => {
  'id': id,
  'type': 'direct',
  'name': null,
  'otherUser': {'id': 'u2', 'displayName': 'Anna', 'avatar': null},
  'lastMessage': {
    'content': lastContent,
    'senderId': 'u2',
    'createdAt': updatedAt,
    'deleted': false,
  },
  'unreadCount': unread,
  'lastSeenAt': null,
  'lastReadSeq': lastReadSeq,
  'otherLastReadSeq': 0,
  'createdAt': '2026-08-10 10:00:00',
  'updatedAt': updatedAt,
};

Map<String, dynamic> _messageJson(
  String id,
  int seq,
  String conversationId,
  String content,
) => {
  'id': id,
  'seq': seq,
  'conversationId': conversationId,
  'senderId': 'u2',
  'sender': {'id': 'u2', 'displayName': 'Anna', 'avatar': null},
  'type': 'text',
  'content': content,
  'payload': null,
  'clientId': null,
  'editedAt': null,
  'deleted': false,
  'createdAt': '2026-08-16 10:00:00',
};

Map<String, dynamic> _syncJson({
  required int seq,
  bool hasMore = false,
  List<Map<String, dynamic>> events = const [],
  List<Map<String, dynamic>> conversations = const [],
}) => {
  'data': {'events': events, 'conversations': conversations, 'typing': {}},
  'meta': {'seq': seq, 'hasMore': hasMore},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockApiClient api;
  late ChatService service;
  var notified = 0;

  setUp(() {
    api = _MockApiClient();
    service = ChatService(api: api, auth: _FakeAuth(api));
    notified = 0;
    service.addListener(() => notified++);
  });

  tearDown(() {
    service.dispose();
  });

  test(
    'refreshConversations lädt und sortiert nach updatedAt absteigend',
    () async {
      api.responses.add({
        'data': [
          _conversationJson('convA', updatedAt: '2026-08-16 09:00:00'),
          _conversationJson('convB', updatedAt: '2026-08-16 11:00:00'),
        ],
      });

      await service.refreshConversations();

      expect(service.conversations.map((c) => c.id), ['convB', 'convA']);
      expect(service.conversations.first.otherUser?.displayName, 'Anna');
      expect(service.conversations.first.lastMessage?.content, 'Hallo');
      expect(notified, 1);
    },
  );

  test(
    'Sync folgt hasMore, übernimmt Events und Unread-Zusammenfassung',
    () async {
      api.responses.add({
        'data': [_conversationJson('convA')],
      });
      await service.refreshConversations();

      api.responses.add(
        _syncJson(
          seq: 10,
          hasMore: true,
          conversations: [
            {'conversationId': 'convA', 'unreadCount': 5},
          ],
        ),
      );
      api.responses.add(
        _syncJson(
          seq: 12,
          events: [
            {
              'seq': 11,
              'conversationId': 'convA',
              'actorId': 'u2',
              'type': 'message_created',
              'messageId': 'm2',
              'message': _messageJson('m2', 9, 'convA', 'Wie geht es dir?'),
            },
          ],
        ),
      );

      service.registerActive();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(api.calledQueryParams[1], {'limit': '200'});
      expect(api.calledQueryParams[2], {'limit': '200', 'after': '10'});
      expect(service.conversations.first.unreadCount, 5);
      expect(
        service.conversations.first.lastMessage?.content,
        'Wie geht es dir?',
      );
      expect(service.messagesOf('convA')?.last.content, 'Wie geht es dir?');
      expect(service.syncing, isFalse);
    },
  );

  test('unbekannte Konversation im Sync wird nachgeladen', () async {
    api.responses.add(
      _syncJson(
        seq: 3,
        conversations: [
          {'conversationId': 'convX', 'unreadCount': 1},
        ],
      ),
    );
    api.responses.add({'data': _conversationJson('convX')});

    service.registerActive();
    await Future.delayed(const Duration(milliseconds: 100));

    expect(api.calledPaths, contains('/chat/conversations/convX'));
    expect(service.conversations.map((c) => c.id), ['convX']);
    expect(service.conversations.first.otherUser?.displayName, 'Anna');
  });

  test('sendMessage schickt clientId und aktualisiert die Vorschau', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();

    api.responses.add({'data': _messageJson('m1', 7, 'convA', 'Hi!')});

    final message = await service.sendMessage('convA', 'Hi!');

    expect(message.content, 'Hi!');
    expect(api.calledBodies.first?['type'], 'text');
    expect(api.calledBodies.first?['clientId'], isNotEmpty);
    expect(service.conversations.first.lastMessage?.content, 'Hi!');
    expect(service.messagesOf('convA'), hasLength(1));
  });

  test(
    'markConversationRead postet höchsten seq und nullt Unread lokal',
    () async {
      api.responses.add({
        'data': [_conversationJson('convA', unread: 3)],
      });
      await service.refreshConversations();

      api.responses.add({
        'data': [
          _messageJson('m1', 5, 'convA', 'a'),
          _messageJson('m2', 8, 'convA', 'b'),
        ],
      });
      await service.getMessages('convA');

      await service.markConversationRead('convA');

      expect(api.calledPaths, contains('/chat/conversations/convA/read'));
      expect(api.calledBodies.last, {'seq': 8});
      expect(service.conversations.first.unreadCount, 0);

      // Zweiter Aufruf (z. B. Screen-Sync-Trigger) darf NICHT erneut
      // posten — sonst entsteht die POST-Schleife wie im Feld gesehen.
      await service.markConversationRead('convA');
      expect(
        api.calledPaths.where((p) => p == '/chat/conversations/convA/read'),
        hasLength(1),
      );
    },
  );

  test('markConversationRead ist No-op, wenn alles gelesen ist', () async {
    api.responses.add({
      'data': [_conversationJson('convA', lastReadSeq: 8)],
    });
    await service.refreshConversations();

    api.responses.add({
      'data': [
        _messageJson('m1', 5, 'convA', 'a'),
        _messageJson('m2', 8, 'convA', 'b'),
      ],
    });
    await service.getMessages('convA');

    final notifiedBefore = notified;
    await service.markConversationRead('convA');

    expect(api.calledPaths, isNot(contains('/chat/conversations/convA/read')));
    expect(notified, notifiedBefore);
  });

  test(
    'markConversationRead ohne geladene Nachrichten ist ein No-op',
    () async {
      api.responses.add({
        'data': [_conversationJson('convA', unread: 3)],
      });
      await service.refreshConversations();

      await service.markConversationRead('convA');

      expect(
        api.calledPaths,
        isNot(contains('/chat/conversations/convA/read')),
      );
      expect(service.conversations.first.unreadCount, 3);
    },
  );

  test(
    'refreshConversations überspringt Abruf innerhalb der TTL, force lädt neu',
    () async {
      var now = DateTime(2026, 8, 16, 12, 0, 0);
      service = ChatService(api: api, auth: _FakeAuth(api), clock: () => now);

      int conversationCalls() =>
          api.calledPaths.where((p) => p == '/chat/conversations').length;

      api.responses.add({
        'data': [_conversationJson('convA')],
      });
      await service.refreshConversations();
      expect(conversationCalls(), 1);

      // Innerhalb der TTL (60 s) wird nicht erneut geladen.
      now = now.add(const Duration(seconds: 30));
      await service.refreshConversations();
      expect(conversationCalls(), 1);

      // Pull-to-Refresh erzwingt einen frischen Abruf.
      await service.refreshConversations(force: true);
      expect(conversationCalls(), 2);

      // Nach Ablauf der TTL wird wieder geladen.
      now = now.add(const Duration(seconds: 61));
      api.responses.add({
        'data': [_conversationJson('convB')],
      });
      await service.refreshConversations();
      expect(conversationCalls(), 3);
      expect(service.conversations.single.id, 'convB');
    },
  );

  // ─── Phase 2: Edit, Delete, Typing ───────────────────────────────────

  test('editMessage patched Inhalt und aktualisiert Preview', () async {
    api.responses.add({
      'data': [_conversationJson('convA', lastContent: 'Alt')],
    });
    await service.refreshConversations();

    api.responses.add({
      'data': [_messageJson('m1', 5, 'convA', 'Alt')],
    });
    await service.getMessages('convA');

    api.responses.add({
      'data': _messageJson('m1', 5, 'convA', 'Neu'),
    });

    final updated = await service.editMessage('convA', 'm1', 'Neu');

    expect(updated.content, 'Neu');
    expect(api.calledPaths.last, '/chat/messages/m1');
    expect(api.calledBodies.last, {'content': 'Neu'});
    expect(service.messagesOf('convA')!.single.content, 'Neu');
    expect(service.conversations.first.lastMessage?.content, 'Neu');
  });

  test('deleteMessage ruft API auf und markiert lokal als gelöscht', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();

    api.responses.add({
      'data': [_messageJson('m1', 5, 'convA', 'Inhalt')],
    });
    await service.getMessages('convA');

    await service.deleteMessage('convA', 'm1');

    expect(api.calledPaths.last, '/chat/messages/m1');
    final msg = service.messagesOf('convA')!.single;
    expect(msg.deleted, isTrue);
    expect(msg.content, isEmpty);
  });

  test(
    'sendTyping debounced: zwei Aufrufe innerhalb 3 s → nur ein POST',
    () async {
      service.sendTyping('convA');
      service.sendTyping('convA');

      await Future.delayed(const Duration(milliseconds: 50));

      final typingCalls = api.calledPaths
          .where((p) => p == '/chat/conversations/convA/typing')
          .length;
      expect(typingCalls, 1);
    },
  );

  test('typingUsers wird aus Sync übernommen', () async {
    api.responses.add({
      'data': {
        'events': <Map<String, dynamic>>[],
        'conversations': <Map<String, dynamic>>[],
        'typing': {
          'convA': ['u2'],
        },
      },
      'meta': {'seq': 1, 'hasMore': false},
    });

    service.registerActive();
    await Future.delayed(const Duration(milliseconds: 100));

    expect(service.typingUsers, {
      'convA': ['u2'],
    });
  });
}
