import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';
import 'package:sinclear_beyond/core/storage/token_storage.dart';
import 'package:sinclear_beyond/features/auth/services/auth_service.dart';
import 'package:sinclear_beyond/features/chat/models/chat_models.dart';
import 'package:sinclear_beyond/features/chat/services/centrifugo_service.dart';
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

  @override
  String? get userId => 'u1';
}

/// Fake-Transport: streamt testbare Events und protokolliert Publish-Aufrufe.
class _FakeCentrifugo extends CentrifugoService {
  _FakeCentrifugo(AuthService auth) : super(auth: auth);

  final _controller = StreamController<CentrifugoEvent>.broadcast();
  final List<String> subscribed = [];
  final List<({String conversationId, bool typing})> typingCalls = [];
  final List<
    ({String conversationId, String messageId, String emoji, bool add})
  >
  reactionCalls = [];
  Object? reactionException;
  final List<
    ({
      String conversationId,
      String clientId,
      String content,
      String? replyToMessageId,
    })
  >
  messageCalls = [];
  Object? messageException;
  int connectCalls = 0;

  @override
  Stream<CentrifugoEvent> get events => _controller.stream;

  @override
  Future<void> connect() async => connectCalls++;

  @override
  Future<void> subscribe(String conversationId) async {
    subscribed.add(conversationId);
  }

  @override
  Future<void> publishTyping(String conversationId, bool typing) async {
    typingCalls.add((conversationId: conversationId, typing: typing));
  }

  @override
  Future<void> publishMessage(
    String conversationId,
    String clientId,
    String content,
    String? replyToMessageId,
  ) async {
    final error = messageException;
    if (error != null) throw error;
    messageCalls.add((
      conversationId: conversationId,
      clientId: clientId,
      content: content,
      replyToMessageId: replyToMessageId,
    ));
  }

  @override
  Future<void> publishReaction(
    String conversationId,
    String messageId,
    String emoji,
    bool add,
  ) async {
    final error = reactionException;
    if (error != null) throw error;
    reactionCalls.add((
      conversationId: conversationId,
      messageId: messageId,
      emoji: emoji,
      add: add,
    ));
  }

  void emit(CentrifugoEvent event) => _controller.add(event);
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
  String content, {
  List<Map<String, dynamic>> reactions = const [],
}) => {
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
  'reactions': reactions,
  'createdAt': '2026-08-16 10:00:00',
};

Map<String, dynamic> _groupConversationJson(
  String id, {
  required int memberCount,
}) => {
  'id': id,
  'type': 'group',
  'name': 'Sommerurlaub',
  'image': null,
  'otherUser': null,
  'lastMessage': null,
  'unreadCount': 0,
  'lastSeenAt': null,
  'lastReadSeq': 0,
  'otherLastReadSeq': null,
  'memberCount': memberCount,
  'createdAt': '2026-08-10 10:00:00',
  'updatedAt': '2026-08-16 10:00:00',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockApiClient api;
  late _FakeCentrifugo centrifugo;
  late ChatService service;
  var notified = 0;

  setUp(() {
    api = _MockApiClient();
    centrifugo = _FakeCentrifugo(_FakeAuth(api));
    service = ChatService(
      api: api,
      auth: _FakeAuth(api),
      centrifugo: centrifugo,
    );
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
    'message_created-Event fügt Nachricht hinzu und aktualisiert Vorschau',
    () async {
      api.responses.add({
        'data': [_conversationJson('convA', lastContent: 'Alt')],
      });
      await service.refreshConversations();

      centrifugo.emit(
        CentrifugoEvent(
          conversationId: 'convA',
          data: {
            'type': 'message_created',
            'message': _messageJson('m2', 9, 'convA', 'Wie geht es dir?'),
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(
        service.conversations.first.lastMessage?.content,
        'Wie geht es dir?',
      );
      expect(service.messagesOf('convA')?.last.content, 'Wie geht es dir?');
      expect(service.syncing, isFalse);
    },
  );

  test('message_deleted-Event markiert Nachricht lokal als gelöscht', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();
    api.responses.add({
      'data': [_messageJson('m1', 5, 'convA', 'Inhalt')],
    });
    await service.getMessages('convA');

    centrifugo.emit(
      const CentrifugoEvent(
        conversationId: 'convA',
        data: {'type': 'message_deleted', 'messageId': 'm1'},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final msg = service.messagesOf('convA')!.single;
    expect(msg.deleted, isTrue);
    expect(msg.content, isEmpty);
  });

  test('read-Event setzt otherLastReadSeq', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();

    centrifugo.emit(
      const CentrifugoEvent(
        conversationId: 'convA',
        data: {'type': 'read', 'userId': 'u2', 'lastReadSeq': 7},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(service.conversations.first.otherLastReadSeq, 7);
  });

  test('message_created parst das eingebettete Zitat', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();

    centrifugo.emit(
      const CentrifugoEvent(
        conversationId: 'convA',
        data: {
          'type': 'message_created',
          'message': {
            'id': 'm2',
            'seq': 8,
            'conversationId': 'convA',
            'senderId': 'u1',
            'sender': {'id': 'u1', 'displayName': 'Ich', 'avatar': null},
            'type': 'text',
            'content': 'Antwort',
            'payload': null,
            'clientId': 'c1',
            'replyToMessageId': 'm1',
            'replyTo': {
              'id': 'm1',
              'seq': 5,
              'senderId': 'u2',
              'sender': {'id': 'u2', 'displayName': 'Anna', 'avatar': null},
              'type': 'text',
              'content': 'Original',
              'deleted': false,
            },
            'editedAt': null,
            'deleted': false,
            'reactions': [],
            'createdAt': '2026-08-16 10:00:00',
          },
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final msg = service.messagesOf('convA')!.singleWhere((m) => m.id == 'm2');
    expect(msg.replyToMessageId, 'm1');
    expect(msg.replyTo?.content, 'Original');
    expect(msg.replyTo?.sender.displayName, 'Anna');
  });

  test('message_deleted aktualisiert Zitate in Antworten', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();
    api.responses.add({
      'data': [
        {
          'id': 'm1',
          'seq': 5,
          'conversationId': 'convA',
          'senderId': 'u2',
          'sender': {'id': 'u2', 'displayName': 'Anna', 'avatar': null},
          'type': 'text',
          'content': 'Original',
          'payload': null,
          'clientId': null,
          'replyToMessageId': null,
          'replyTo': null,
          'editedAt': null,
          'deleted': false,
          'reactions': [],
          'createdAt': '2026-08-16 10:00:00',
        },
        {
          'id': 'm2',
          'seq': 8,
          'conversationId': 'convA',
          'senderId': 'u1',
          'sender': {'id': 'u1', 'displayName': 'Ich', 'avatar': null},
          'type': 'text',
          'content': 'Antwort',
          'payload': null,
          'clientId': 'c1',
          'replyToMessageId': 'm1',
          'replyTo': {
            'id': 'm1',
            'seq': 5,
            'senderId': 'u2',
            'sender': {'id': 'u2', 'displayName': 'Anna', 'avatar': null},
            'type': 'text',
            'content': 'Original',
            'deleted': false,
          },
          'editedAt': null,
          'deleted': false,
          'reactions': [],
          'createdAt': '2026-08-16 10:01:00',
        },
      ],
    });
    await service.getMessages('convA');

    centrifugo.emit(
      const CentrifugoEvent(
        conversationId: 'convA',
        data: {'type': 'message_deleted', 'messageId': 'm1'},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final reply = service.messagesOf('convA')!.firstWhere((m) => m.id == 'm2');
    expect(reply.replyTo?.deleted, isTrue);
    expect(reply.replyTo?.content, isEmpty);
  });

  test('reaction_updated-Event ersetzt die Reaktions-Summary', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();
    api.responses.add({
      'data': [_messageJson('m1', 5, 'convA', 'Inhalt')],
    });
    await service.getMessages('convA');

    centrifugo.emit(
      const CentrifugoEvent(
        conversationId: 'convA',
        data: {
          'type': 'reaction_updated',
          'messageId': 'm1',
          'reactions': [
            {
              'emoji': '👍',
              'count': 2,
              'users': [
                {'id': 'u1', 'displayName': 'Ich', 'avatar': null},
                {'id': 'u2', 'displayName': 'Anna', 'avatar': null},
              ],
            },
          ],
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final reactions = service.messagesOf('convA')!.single.reactions;
    expect(reactions, hasLength(1));
    expect(reactions.single.emoji, '👍');
    expect(reactions.single.count, 2);
    expect(reactions.single.isMine('u1'), isTrue);
  });

  test('toggleReaction setzt optimistisch und sendet add=true', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();
    api.responses.add({
      'data': [_messageJson('m1', 5, 'convA', 'Inhalt')],
    });
    await service.getMessages('convA');
    final message = service.messagesOf('convA')!.single;

    await service.toggleReaction('convA', message, '👍');

    expect(centrifugo.reactionCalls, hasLength(1));
    final call = centrifugo.reactionCalls.single;
    expect(call.messageId, 'm1');
    expect(call.emoji, '👍');
    expect(call.add, isTrue);
    final reactions = service.messagesOf('convA')!.single.reactions;
    expect(reactions.single.emoji, '👍');
    expect(reactions.single.isMine('u1'), isTrue);
  });

  test('toggleReaction entfernt eigene Reaktion (add=false)', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();
    api.responses.add({
      'data': [
        _messageJson(
          'm1',
          5,
          'convA',
          'Inhalt',
          reactions: [
            {
              'emoji': '👍',
              'count': 1,
              'users': [
                {'id': 'u1', 'displayName': 'Ich', 'avatar': null},
              ],
            },
          ],
        ),
      ],
    });
    await service.getMessages('convA');
    final message = service.messagesOf('convA')!.single;

    await service.toggleReaction('convA', message, '👍');

    expect(centrifugo.reactionCalls.single.add, isFalse);
    expect(service.messagesOf('convA')!.single.reactions, isEmpty);
  });

  test('toggleReaction rollt bei Publish-Fehler zurück', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();
    api.responses.add({
      'data': [_messageJson('m1', 5, 'convA', 'Inhalt')],
    });
    await service.getMessages('convA');
    final message = service.messagesOf('convA')!.single;
    centrifugo.reactionException = StateError('offline');

    await expectLater(
      service.toggleReaction('convA', message, '👍'),
      throwsA(isA<StateError>()),
    );

    expect(service.messagesOf('convA')!.single.reactions, isEmpty);
  });

  test('DirectMessage parst Reaktionen aus JSON', () {
    final message = DirectMessage.fromJson(
      _messageJson(
        'm1',
        5,
        'convA',
        'Inhalt',
        reactions: [
          {
            'emoji': '❤',
            'count': 1,
            'users': [
              {'id': 'u1', 'displayName': 'Ich', 'avatar': null},
            ],
          },
        ],
      ),
    );

    expect(message.reactions.single.emoji, '❤');
    expect(message.reactions.single.isMine('u1'), isTrue);
    expect(message.reactions.single.isMine('u2'), isFalse);
  });

  test('typing-Event trägt User ein und entfernt ihn wieder', () async {
    centrifugo.emit(
      const CentrifugoEvent(
        conversationId: 'convA',
        data: {'type': 'typing', 'userId': 'u2', 'typing': true},
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(service.typingUsers['convA'], ['u2']);

    centrifugo.emit(
      const CentrifugoEvent(
        conversationId: 'convA',
        data: {'type': 'typing', 'userId': 'u2', 'typing': false},
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(service.typingUsers['convA'], isNull);
  });

  test(
    'registerActive verbindet und abonniert bekannte Konversationen',
    () async {
      api.responses.add({
        'data': [_conversationJson('convA')],
      });
      await service.refreshConversations();

      service.registerActive();
      await Future<void>.delayed(Duration.zero);

      expect(centrifugo.connectCalls, greaterThan(0));
      expect(centrifugo.subscribed, contains('convA'));
    },
  );

  test('sendMessage sendet über WS mit clientId', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();

    await service.sendMessage('convA', 'Hi!');

    expect(centrifugo.messageCalls, hasLength(1));
    final call = centrifugo.messageCalls.single;
    expect(call.conversationId, 'convA');
    expect(call.content, 'Hi!');
    expect(call.clientId, isNotEmpty);
    expect(call.replyToMessageId, isNull);
    // Kein REST-Send mehr.
    expect(
      api.calledPaths.where((p) => p.endsWith('/messages')),
      isEmpty,
    );
  });

  test('sendMessage überträgt replyToMessageId', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();

    await service.sendMessage('convA', 'Antwort', replyToMessageId: 'm1');

    expect(centrifugo.messageCalls.single.replyToMessageId, 'm1');
  });

  test('sendMessage reicht Publish-Fehler weiter', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();
    centrifugo.messageException = StateError('rate limit');

    expect(
      () => service.sendMessage('convA', 'Hi!'),
      throwsA(isA<StateError>()),
    );
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
      final previous = service;
      service = ChatService(
        api: api,
        auth: _FakeAuth(api),
        centrifugo: centrifugo,
        clock: () => now,
      );
      addTearDown(previous.dispose);

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

    api.responses.add({'data': _messageJson('m1', 5, 'convA', 'Neu')});

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
    'sendTyping debounced: zwei Aufrufe innerhalb 3 s → nur ein Publish',
    () async {
      service.sendTyping('convA');
      service.sendTyping('convA');

      await Future.delayed(const Duration(milliseconds: 50));

      expect(centrifugo.typingCalls, hasLength(1));
      expect(centrifugo.typingCalls.single.typing, isTrue);
    },
  );

  // ─── Presence & Live-Unread ───────────────────────────────────────────

  test('eingehende Fremd-Nachricht erhöht Unread lokal', () async {
    api.responses.add({
      'data': [_conversationJson('convA')],
    });
    await service.refreshConversations();
    expect(service.unreadConversationIds, isEmpty);

    centrifugo.emit(
      CentrifugoEvent(
        conversationId: 'convA',
        data: {
          'type': 'message_created',
          'message': _messageJson('m1', 9, 'convA', 'Hi'),
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(service.conversations.first.unreadCount, 1);
    expect(service.unreadConversationIds, contains('convA'));
  });

  test(
    'eigene Nachricht und gewatchte Konversation erhöhen Unread nicht',
    () async {
      api.responses.add({
        'data': [_conversationJson('convA')],
      });
      await service.refreshConversations();

      final own = {
        ..._messageJson('m1', 9, 'convA', 'Hi'),
        'senderId': 'u1',
        'sender': {'id': 'u1', 'displayName': 'Ich', 'avatar': null},
      };
      centrifugo.emit(
        CentrifugoEvent(
          conversationId: 'convA',
          data: {'type': 'message_created', 'message': own},
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.conversations.first.unreadCount, 0);

      service.watchConversation('convA');
      centrifugo.emit(
        CentrifugoEvent(
          conversationId: 'convA',
          data: {
            'type': 'message_created',
            'message': _messageJson('m2', 10, 'convA', 'Hi'),
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.conversations.first.unreadCount, 0);
    },
  );

  test('presence_snapshot setzt anwesende Nutzer', () async {
    centrifugo.emit(
      const CentrifugoEvent(
        conversationId: 'convA',
        data: {
          'type': 'presence_snapshot',
          'clients': {'c1': 'u1', 'c2': 'u2'},
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(service.isPresent('convA', 'u2'), isTrue);
    expect(service.isPresent('convA', 'u3'), isFalse);
    expect(service.presentCount('convA'), 2);
  });

  test('presence_join/leave pflegt Anwesenheit und zuletzt online', () async {
    centrifugo.emit(
      const CentrifugoEvent(
        conversationId: 'convA',
        data: {'type': 'presence_join', 'client': 'c3', 'user': 'u3'},
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(service.isPresent('convA', 'u3'), isTrue);
    expect(service.lastSeenAt('u3'), isNull);

    centrifugo.emit(
      const CentrifugoEvent(
        conversationId: 'convA',
        data: {'type': 'presence_leave', 'client': 'c3', 'user': 'u3'},
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(service.isPresent('convA', 'u3'), isFalse);
    expect(service.lastSeenAt('u3'), isNotNull);
  });

  test('Gruppen-Konversation parst memberCount', () async {
    api.responses.add({
      'data': [_groupConversationJson('groupA', memberCount: 4)],
    });
    await service.refreshConversations();

    expect(service.conversations.single.type, 'group');
    expect(service.conversations.single.memberCount, 4);
  });
}
