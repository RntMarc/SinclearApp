// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/chat_models.dart';
import 'centrifugo_service.dart';

final _log = Logger('chat.service');

/// Hält den Chat-Zustand: Konversationsliste, Nachrichten je Konversation
/// und die Echtzeit-Events aus Centrifugo.
///
/// Die REST-API bleibt Quelle der Wahrheit und wird zum Laden (Liste,
/// Verlauf), Senden sowie für Bearbeiten/Löschen/Lesestand genutzt. Alle
/// laufenden Änderungen kommen über den WebSocket des [CentrifugoService];
/// es gibt kein Polling mehr.
///
/// Die Verbindung wird nur gehalten, solange ein UI-Teilnehmer aktiv ist
/// ([registerActive]/[unregisterActive]) und die App im Vordergrund läuft.
class ChatService extends ChangeNotifier with WidgetsBindingObserver {
  ChatService({
    required ApiClient api,
    required AuthService auth,
    CentrifugoService? centrifugo,
    this.conversationsTtl = const Duration(seconds: 60),
    DateTime Function() clock = DateTime.now,
  }) : _api = api,
       _auth = auth,
       _centrifugo = centrifugo ?? CentrifugoService(auth: auth),
       _clock = clock {
    _eventSub = _centrifugo.events.listen(_onCentrifugoEvent);
    _reconnectedSub = _centrifugo.onReconnected.listen(_onReconnected);
    WidgetsBinding.instance.addObserver(this);
  }

  final ApiClient _api;
  final AuthService _auth;
  final CentrifugoService _centrifugo;
  StreamSubscription<CentrifugoEvent>? _eventSub;
  StreamSubscription<void>? _reconnectedSub;

  /// Mindestabstand zwischen zwei vollen Konversationslisten-Abrufen.
  /// Verhindert, dass jeder Tab-Wechsel die Liste (inkl. Base64-Profilbilder)
  /// erneut vom Server lädt.
  final Duration conversationsTtl;

  final DateTime Function() _clock;

  final List<ChatConversation> _conversations = [];
  final Map<String, List<DirectMessage>> _messages = {};

  /// Zeitpunkt des letzten erfolgreichen [refreshConversations].
  DateTime? _lastConversationsRefresh;

  int _activeCount = 0;
  final Set<String> _watched = {};

  final Map<String, List<String>> _typingUsers = {};
  final Map<String, Timer> _typingExpiry = {};
  Timer? _typingTimer;
  bool _typingSent = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  /// Anwesende Clients je Konversation: conversationId → {clientId → userId}.
  ///
  /// Centrifugo liefert die Presence pro Channel (`chat:<id>`) – Join/Leave
  /// eines Teilnehmers bedeuten „hat diesen Chat geöffnet". Wird beim
  /// Subscribe als Snapshot befüllt und über Join/Leave-Deltas gepflegt.
  final Map<String, Map<String, String>> _presentClients = {};

  /// Lokal beobachteter Zeitpunkt des letzten Verlassens eines Users
  /// (aus dem Leave-Event), für „zuletzt online".
  final Map<String, DateTime> _lastSeenAt = {};

  /// Nur wenn die App im Vordergrund ist (resumed) wird verbunden.
  bool get _foreground => _lifecycle == AppLifecycleState.resumed;

  Future<String> _token() => _auth.getAccessToken();

  /// Konversationen, neueste Aktivität zuerst.
  List<ChatConversation> get conversations => List.unmodifiable(_conversations);

  /// IDs der Konversationen mit ungelesenen Nachrichten (lokaler Zähler).
  Set<String> get unreadConversationIds => {
    for (final c in _conversations)
      if (c.unreadCount > 0) c.id,
  };

  /// Nachrichten einer Konversation (aufsteigend nach `seq`), `null` wenn
  /// noch nicht geladen.
  List<DirectMessage>? messagesOf(String conversationId) {
    final list = _messages[conversationId];
    return list == null ? null : List.unmodifiable(list);
  }

  bool get syncing => false;

  /// Tippzustand je Konversation aus den Centrifugo-Events.
  /// Map: conversationId → [userId, …].
  Map<String, List<String>> get typingUsers => _typingUsers;

  /// Ob [userId] gerade im Chat-Channel von [conversationId] anwesend ist.
  bool isPresent(String conversationId, String userId) =>
      _presentClients[conversationId]?.containsValue(userId) ?? false;

  /// Anzahl anwesender Nutzer in [conversationId] (dedupliziert).
  int presentCount(String conversationId) =>
      _presentClients[conversationId]?.values.toSet().length ?? 0;

  /// Zuletzt beobachteter Zeitpunkt, an dem [userId] den Chat verließ.
  DateTime? lastSeenAt(String userId) => _lastSeenAt[userId];

  /// Chat-UI sichtbar: hält die Echtzeitverbindung aktiv (ref-counted, damit
  /// Tab und Konversations-Screen sich nicht gegenseitig stoppen).
  void registerActive() {
    _activeCount++;
    _log.info('registerActive → activeCount=$_activeCount');
    _syncRealtime();
  }

  void unregisterActive() {
    if (_activeCount > 0) _activeCount--;
    _log.info('unregisterActive → activeCount=$_activeCount');
    _syncRealtime();
  }

  /// Abonniert einen Channel, solange die Konversation sichtbar ist.
  void watchConversation(String conversationId) {
    _log.fine('watchConversation($conversationId)');
    _watched.add(conversationId);
    _syncRealtime();
  }

  void unwatchConversation(String conversationId) {
    _log.fine('unwatchConversation($conversationId)');
    _watched.remove(conversationId);
    _syncRealtime();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _log.info('Lifecycle → $state');
    _syncRealtime();
  }

  /// Hält Verbindung und Subscriptions im Einklang mit Aktivität und
  /// Vordergrund. Bei Hintergrund/Inaktivität wird getrennt.
  void _syncRealtime() {
    _log.fine(
      '_syncRealtime: activeCount=$_activeCount foreground=$_foreground '
      'watched=$_watched convCount=${_conversations.length}',
    );
    if (_activeCount == 0 || !_foreground) {
      _log.info('_syncRealtime: disconnecting (inactive or background)');
      unawaited(_centrifugo.disconnect());
      return;
    }
    unawaited(_centrifugo.connect());
    final targets = {..._watched};
    if (_activeCount > 0) {
      targets.addAll(_conversations.map((c) => c.id));
    }
    for (final id in targets) {
      if (_centrifugo.isSubscribed(id)) continue;
      _log.info('_syncRealtime: subscribing to $id');
      unawaited(_centrifugo.subscribe(id));
    }
  }

  // ─── Reconnect-Catch-up ─────────────────────────────────────────────

  void _onReconnected(void _) {
    _log.info('Reconnected – catching up messages');
    final ids = {..._watched, ..._messages.keys};
    for (final id in ids) {
      unawaited(_catchUpConversation(id));
    }
    unawaited(refreshConversations(force: true));
  }

  Future<void> _catchUpConversation(String conversationId) async {
    try {
      final before = _messages[conversationId]?.length ?? 0;
      await getMessages(conversationId);
      final after = _messages[conversationId]?.length ?? 0;
      _log.info('Catch-up $conversationId: $before → $after messages');
    } catch (e, st) {
      _log.warning('Catch-up for $conversationId failed', e, st);
    }
  }

  // ─── Echtzeit-Events (Centrifugo) ─────────────────────────────────────

  void _onCentrifugoEvent(CentrifugoEvent event) {
    final data = event.data;
    final type = data['type'] as String?;
    _log.info('Event on ${event.conversationId}: type=$type');
    try {
      // Handle typing events that come without a 'type' wrapper
      // (direct payload: { "typing": true/false, "userId": "..." })
      if (type == null && data.containsKey('typing')) {
        _log.fine(
          'Typing event (no type wrapper): conversationId=${event.conversationId}, userId=${data['userId']}, typing=${data['typing']}',
        );
        _applyTyping(
          event.conversationId,
          userId: data['userId'] as String?,
          typing: data['typing'] == true,
        );
        notifyListeners();
        return;
      }
      switch (type) {
        case 'message_created':
        case 'message_edited':
          final raw = data['message'];
          if (raw is Map<String, dynamic>) {
            final message = DirectMessage.fromJson(raw);
            _upsertMessage(event.conversationId, message);
            if (type == 'message_created') {
              _updatePreview(event.conversationId, message);
              _bumpUnreadIfIncoming(event.conversationId, message);
              // Sofort als gelesen markieren, wenn Konversation offen (_watched)
              // und Nachricht von anderem Nutzer kommt.
              if (_watched.contains(event.conversationId) &&
                  message.senderId != _auth.userId) {
                unawaited(markConversationRead(event.conversationId));
              }
            } else {
              _updatePreviewIfCurrent(event.conversationId, message);
            }
            _log.info(
              '  → ${type == 'message_created' ? 'created' : 'edited'} '
              'msg id=${message.id} seq=${message.seq}',
            );
            notifyListeners();
          } else {
            _log.warning(
              '  → $type: data[message] is ${raw.runtimeType}, '
              'expected Map – event dropped',
            );
          }
        case 'message_deleted':
          final messageId = data['messageId'] as String?;
          if (messageId != null) {
            _applyDeleted(event.conversationId, messageId);
            _log.info('  → deleted msg id=$messageId');
            notifyListeners();
          }
        case 'read':
          _applyRead(
            event.conversationId,
            userId: data['userId'] as String?,
            lastReadSeq: data['lastReadSeq'] as int?,
          );
          _log.fine(
            '  → read userId=${data['userId']} '
            'lastReadSeq=${data['lastReadSeq']}',
          );
          notifyListeners();
        case 'typing':
          _log.fine(
            'Typing event: conversationId=${event.conversationId}, userId=${data['userId']}, typing=${data['typing']}',
          );
          _applyTyping(
            event.conversationId,
            userId: data['userId'] as String?,
            typing: data['typing'] == true,
          );
          notifyListeners();
        case 'presence_snapshot':
          _applyPresenceSnapshot(event.conversationId, data['clients']);
        case 'presence_join':
          _applyPresenceJoin(
            event.conversationId,
            clientId: data['client'] as String?,
            userId: data['user'] as String?,
          );
        case 'presence_leave':
          _applyPresenceLeave(
            event.conversationId,
            clientId: data['client'] as String?,
            userId: data['user'] as String?,
          );
        case 'recovered_gap':
          _log.info('  → recovered_gap – reloading via REST');
          unawaited(_recoverGap(event.conversationId));
        default:
          _log.warning('  → unknown type: $type – event dropped');
      }
    } catch (e, st) {
      _log.severe(
        'Event handling failed for type=$type '
        'on ${event.conversationId}',
        e,
        st,
      );
    }
  }

  /// Nach einer nicht vollständig recovernen Subscription den Verlauf per
  /// REST nachladen, damit keine Nachricht verloren geht.
  Future<void> _recoverGap(String conversationId) async {
    if (!_messages.containsKey(conversationId)) return;
    try {
      await getMessages(conversationId);
    } catch (e, st) {
      _log.warning('Recover gap for $conversationId failed', e, st);
    }
  }

  void _applyDeleted(String conversationId, String messageId) {
    final list = _messages[conversationId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;
    final old = list[idx];
    final deleted = _asDeleted(old);
    list[idx] = deleted;
    _updatePreviewIfCurrent(conversationId, deleted);
  }

  void _applyRead(String conversationId, {String? userId, int? lastReadSeq}) {
    if (userId == null || lastReadSeq == null) return;
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) return;
    final c = _conversations[index];
    final isOwn = userId == _auth.userId;
    _conversations[index] = ChatConversation(
      id: c.id,
      type: c.type,
      name: c.name,
      image: c.image,
      otherUser: c.otherUser,
      lastMessage: c.lastMessage,
      unreadCount: c.unreadCount,
      lastSeenAt: c.lastSeenAt,
      lastReadSeq: isOwn ? lastReadSeq : c.lastReadSeq,
      otherLastReadSeq: isOwn ? c.otherLastReadSeq : lastReadSeq,
      memberCount: c.memberCount,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
  }

  void _applyTyping(
    String conversationId, {
    String? userId,
    required bool typing,
  }) {
    if (userId == null || userId == _auth.userId) return;
    final current = {...(_typingUsers[conversationId] ?? const <String>[])};
    final timerKey = '$conversationId:$userId';
    _typingExpiry[timerKey]?.cancel();
    if (typing) {
      current.add(userId);
      _typingExpiry[timerKey] = Timer(
        const Duration(seconds: 5),
        () => _removeTyping(conversationId, userId),
      );
    } else {
      current.remove(userId);
    }
    if (current.isEmpty) {
      _typingUsers.remove(conversationId);
    } else {
      _typingUsers[conversationId] = current.toList();
    }
  }

  void _removeTyping(String conversationId, String userId) {
    final current = _typingUsers[conversationId];
    if (current == null) return;
    final next = current.where((u) => u != userId).toList();
    if (next.isEmpty) {
      _typingUsers.remove(conversationId);
    } else {
      _typingUsers[conversationId] = next;
    }
    notifyListeners();
  }

  /// Erhöht den lokalen Unread-Zähler bei eingehenden Fremd-Nachrichten.
  ///
  /// Eigene Nachrichten und Konversationen, die gerade geöffnet sind
  /// ([_watched]), zählen nicht – dort markiert der Screen selbst als gelesen.
  void _bumpUnreadIfIncoming(String conversationId, DirectMessage message) {
    if (message.senderId == _auth.userId) return;
    if (_watched.contains(conversationId)) return;
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) return;
    _conversations[index] = _withUnread(
      _conversations[index],
      _conversations[index].unreadCount + 1,
    );
  }

  void _applyPresenceSnapshot(String conversationId, Object? clients) {
    if (clients is! Map) return;
    _presentClients[conversationId] = {
      for (final entry in clients.entries) '${entry.key}': '${entry.value}',
    };
    _log.fine('presence_snapshot $conversationId: ${clients.length} clients');
    notifyListeners();
  }

  void _applyPresenceJoin(
    String conversationId, {
    String? clientId,
    String? userId,
  }) {
    if (clientId == null || userId == null) return;
    (_presentClients[conversationId] ??= {})[clientId] = userId;
    _log.fine('presence_join $conversationId: $userId');
    notifyListeners();
  }

  void _applyPresenceLeave(
    String conversationId, {
    String? clientId,
    String? userId,
  }) {
    final map = _presentClients[conversationId];
    if (map == null || clientId == null) return;
    map.remove(clientId);
    if (userId != null && userId != _auth.userId) {
      _lastSeenAt[userId] = DateTime.now();
    }
    if (map.isEmpty) _presentClients.remove(conversationId);
    _log.fine('presence_leave $conversationId: $userId');
    notifyListeners();
  }

  // ─── REST-API ─────────────────────────────────────────────────────────

  /// Vollständige Konversationsliste (`GET /chat/conversations`).
  Future<void> refreshConversations({bool force = false}) async {
    final now = _clock();
    final last = _lastConversationsRefresh;
    if (!force && last != null && now.difference(last) < conversationsTtl) {
      return;
    }
    _log.info('refreshConversations(force=$force)');
    try {
      final data = await _api.get(
        '/chat/conversations',
        queryParams: const {'limit': '100'},
        token: await _token(),
      );
      final list = (data['data'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatConversation.fromJson)
          .toList();
      _conversations
        ..clear()
        ..addAll(list);
      _sortConversations();
      _lastConversationsRefresh = _clock();
      _syncRealtime();
      notifyListeners();
      _log.info('refreshConversations: ${list.length} conversations');
    } catch (e, st) {
      _log.severe('refreshConversations failed', e, st);
      rethrow;
    }
  }

  /// Öffnet (get-or-create) die 1:1-Konversation mit [userId].
  Future<ChatConversation> openConversation(String userId) async {
    final data = await _api.post(
      '/chat/conversations',
      body: {'userId': userId},
      token: await _token(),
    );
    final conversation = ChatConversation.fromJson(
      data['data'] as Map<String, dynamic>,
    );
    _upsertConversation(conversation);
    return conversation;
  }

  /// Konversations-Details (`GET /chat/conversations/{id}`).
  Future<ChatConversation> loadConversation(String id) async {
    final data = await _api.get(
      '/chat/conversations/$id',
      token: await _token(),
    );
    final conversation = ChatConversation.fromJson(
      data['data'] as Map<String, dynamic>,
    );
    _upsertConversation(conversation);
    return conversation;
  }

  /// Nachrichten-Verlauf (`GET .../messages`, aufsteigend, Cursor [before]).
  Future<List<DirectMessage>> getMessages(
    String conversationId, {
    int? before,
  }) async {
    final query = <String, String>{'limit': '50'};
    if (before != null) query['before'] = '$before';
    final data = await _api.get(
      '/chat/conversations/$conversationId/messages',
      queryParams: query,
      token: await _token(),
    );
    final list = (data['data'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DirectMessage.fromJson)
        .toList();
    for (final message in list) {
      _upsertMessage(conversationId, message);
    }
    _log.fine('getMessages($conversationId): ${list.length} messages');
    notifyListeners();
    return list;
  }

  /// Sendet eine Nachricht (`POST .../messages`).
  Future<DirectMessage> sendMessage(
    String conversationId,
    String content,
  ) async {
    final data = await _api.post(
      '/chat/conversations/$conversationId/messages',
      body: {
        'clientId': _generateClientId(),
        'type': 'text',
        'content': content,
      },
      token: await _token(),
    );
    final message = DirectMessage.fromJson(
      data['data'] as Map<String, dynamic>,
    );
    _upsertMessage(conversationId, message);
    _updatePreview(conversationId, message);
    notifyListeners();
    return message;
  }

  /// Setzt den eigenen Lesestand (`POST .../read`).
  Future<void> markConversationRead(String conversationId) async {
    final messages = _messages[conversationId];
    if (messages == null || messages.isEmpty) return;
    final maxSeq = messages.fold<int>(0, (max, m) => m.seq > max ? m.seq : max);
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) return;
    final c = _conversations[index];
    if (maxSeq <= c.lastReadSeq && c.unreadCount == 0) return;
    if (maxSeq > c.lastReadSeq) {
      try {
        await _api.post(
          '/chat/conversations/$conversationId/read',
          body: {'seq': maxSeq},
          token: await _token(),
        );
      } catch (e, st) {
        _log.warning('markConversationRead($conversationId) failed', e, st);
      }
    }
    _conversations[index] = ChatConversation(
      id: c.id,
      type: c.type,
      name: c.name,
      image: c.image,
      otherUser: c.otherUser,
      lastMessage: c.lastMessage,
      unreadCount: 0,
      lastSeenAt: c.lastSeenAt,
      lastReadSeq: maxSeq,
      otherLastReadSeq: c.otherLastReadSeq,
      memberCount: c.memberCount,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
    notifyListeners();
  }

  // ─── Nachrichten-Aktionen ──────────────────────────────────────────────

  /// Bearbeitet eine Nachricht (`PATCH /chat/messages/{id}`).
  Future<DirectMessage> editMessage(
    String conversationId,
    String messageId,
    String newContent,
  ) async {
    final data = await _api.patch(
      '/chat/messages/$messageId',
      body: {'content': newContent},
      token: await _token(),
    );
    final updated = DirectMessage.fromJson(
      data['data'] as Map<String, dynamic>,
    );
    _upsertMessage(conversationId, updated);
    _updatePreviewIfCurrent(conversationId, updated);
    notifyListeners();
    return updated;
  }

  /// Löscht eine Nachricht für alle (`DELETE /chat/messages/{id}`).
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _api.delete('/chat/messages/$messageId', token: await _token());
    _applyDeleted(conversationId, messageId);
    notifyListeners();
  }

  /// Sendet den Tippindikator über den Centrifugo-Publish-Proxy.
  void sendTyping(String conversationId) {
    if (_typingSent) return;
    _typingSent = true;
    unawaited(_centrifugo.publishTyping(conversationId, true));
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () => _typingSent = false);
  }

  // ─── Lokale Caches ────────────────────────────────────────────────────

  void _upsertConversation(ChatConversation conversation) {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index >= 0) {
      _conversations[index] = conversation;
    } else {
      _conversations.add(conversation);
    }
    _sortConversations();
  }

  void _sortConversations() {
    _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _upsertMessage(String conversationId, DirectMessage message) {
    final list = _messages.putIfAbsent(conversationId, () => []);
    final index = list.indexWhere((m) => m.id == message.id);
    if (index >= 0) {
      list[index] = message;
    } else {
      list.add(message);
    }
    list.sort((a, b) => a.seq.compareTo(b.seq));
  }

  void _updatePreview(String conversationId, DirectMessage message) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) return;
    final c = _conversations[index];
    _conversations[index] = _withPreview(c, message);
    _sortConversations();
  }

  void _updatePreviewIfCurrent(String conversationId, DirectMessage message) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) return;
    final c = _conversations[index];
    if (c.lastMessage == null || c.lastMessage!.senderId != message.senderId) {
      return;
    }
    _conversations[index] = _withPreview(c, message);
    _sortConversations();
  }

  ChatConversation _withPreview(ChatConversation c, DirectMessage message) =>
      ChatConversation(
        id: c.id,
        type: c.type,
        name: c.name,
        image: c.image,
        otherUser: c.otherUser,
        lastMessage: ChatMessageSummary(
          content: message.deleted ? '' : message.content,
          senderId: message.senderId,
          createdAt: message.createdAt,
          deleted: message.deleted,
        ),
        unreadCount: c.unreadCount,
        lastSeenAt: c.lastSeenAt,
        lastReadSeq: c.lastReadSeq,
        otherLastReadSeq: c.otherLastReadSeq,
        memberCount: c.memberCount,
        createdAt: c.createdAt,
        updatedAt: message.createdAt,
      );

  ChatConversation _withUnread(ChatConversation c, int unreadCount) =>
      ChatConversation(
        id: c.id,
        type: c.type,
        name: c.name,
        image: c.image,
        otherUser: c.otherUser,
        lastMessage: c.lastMessage,
        unreadCount: unreadCount,
        lastSeenAt: c.lastSeenAt,
        lastReadSeq: c.lastReadSeq,
        otherLastReadSeq: c.otherLastReadSeq,
        memberCount: c.memberCount,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );

  DirectMessage _asDeleted(DirectMessage old) => DirectMessage(
    id: old.id,
    seq: old.seq,
    conversationId: old.conversationId,
    senderId: old.senderId,
    sender: old.sender,
    type: old.type,
    content: '',
    payload: null,
    clientId: old.clientId,
    editedAt: old.editedAt,
    deleted: true,
    createdAt: old.createdAt,
  );

  static String _generateClientId() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(0x7fffffff)}';
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _reconnectedSub?.cancel();
    _typingTimer?.cancel();
    for (final timer in _typingExpiry.values) {
      timer.cancel();
    }
    unawaited(_centrifugo.close());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
