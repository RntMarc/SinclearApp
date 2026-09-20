// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/chat_models.dart';
import 'centrifugo_service.dart';

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
    WidgetsBinding.instance.addObserver(this);
  }

  final ApiClient _api;
  final AuthService _auth;
  final CentrifugoService _centrifugo;
  StreamSubscription<CentrifugoEvent>? _eventSub;

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

  /// Channels, für die aktuell eine Centrifugo-Subscription besteht.
  final Set<String> _subscribed = {};

  final Map<String, List<String>> _typingUsers = {};
  final Map<String, Timer> _typingExpiry = {};
  Timer? _typingTimer;
  bool _typingSent = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  /// Nur wenn die App im Vordergrund ist (resumed) wird verbunden.
  bool get _foreground => _lifecycle == AppLifecycleState.resumed;

  Future<String> _token() => _auth.getAccessToken();

  /// Konversationen, neueste Aktivität zuerst.
  List<ChatConversation> get conversations => List.unmodifiable(_conversations);

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

  /// Chat-UI sichtbar: hält die Echtzeitverbindung aktiv (ref-counted, damit
  /// Tab und Konversations-Screen sich nicht gegenseitig stoppen).
  void registerActive() {
    _activeCount++;
    _syncRealtime();
  }

  void unregisterActive() {
    if (_activeCount > 0) _activeCount--;
    _syncRealtime();
  }

  /// Abonniert einen Channel, solange die Konversation sichtbar ist.
  void watchConversation(String conversationId) {
    _watched.add(conversationId);
    _syncRealtime();
  }

  void unwatchConversation(String conversationId) {
    _watched.remove(conversationId);
    _syncRealtime();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _syncRealtime();
  }

  /// Hält Verbindung und Subscriptions im Einklang mit Aktivität und
  /// Vordergrund. Bei Hintergrund/Inaktivität wird getrennt.
  void _syncRealtime() {
    if (_activeCount == 0 || !_foreground) {
      _subscribed.clear();
      unawaited(_centrifugo.disconnect());
      return;
    }
    unawaited(_centrifugo.connect());
    final targets = {..._watched};
    if (_activeCount > 0) {
      targets.addAll(_conversations.map((c) => c.id));
    }
    for (final id in targets) {
      if (_subscribed.contains(id)) continue;
      _subscribed.add(id);
      unawaited(_centrifugo.subscribe(id));
    }
  }

  // ─── Echtzeit-Events (Centrifugo) ─────────────────────────────────────

  void _onCentrifugoEvent(CentrifugoEvent event) {
    final data = event.data;
    switch (data['type']) {
      case 'message_created':
      case 'message_edited':
        final raw = data['message'];
        if (raw is Map<String, dynamic>) {
          final message = DirectMessage.fromJson(raw);
          _upsertMessage(event.conversationId, message);
          if (data['type'] == 'message_created') {
            _updatePreview(event.conversationId, message);
          } else {
            _updatePreviewIfCurrent(event.conversationId, message);
          }
          notifyListeners();
        }
      case 'message_deleted':
        final messageId = data['messageId'] as String?;
        if (messageId != null) {
          _applyDeleted(event.conversationId, messageId);
          notifyListeners();
        }
      case 'read':
        _applyRead(
          event.conversationId,
          userId: data['userId'] as String?,
          lastReadSeq: data['lastReadSeq'] as int?,
        );
        notifyListeners();
      case 'typing':
        _applyTyping(
          event.conversationId,
          userId: data['userId'] as String?,
          typing: data['typing'] == true,
        );
        notifyListeners();
      case 'recovered_gap':
        unawaited(_recoverGap(event.conversationId));
      default:
        break;
    }
  }

  /// Nach einer nicht vollständig recovernen Subscription den Verlauf per
  /// REST nachladen, damit keine Nachricht verloren geht.
  Future<void> _recoverGap(String conversationId) async {
    if (!_messages.containsKey(conversationId)) return;
    try {
      await getMessages(conversationId);
    } catch (e, st) {
      developer.log(
        'Recover gap for $conversationId failed',
        error: e,
        stackTrace: st,
        name: 'chat_service',
      );
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

  // ─── REST-API ─────────────────────────────────────────────────────────

  /// Vollständige Konversationsliste (`GET /chat/conversations`).
  ///
  /// Überspringt den Abruf, wenn die Liste innerhalb von [conversationsTtl]
  /// zuletzt geladen wurde (außer [force]); Echtzeit-Events halten Unread
  /// und Vorschau derweil aktuell. Der volle Abruf transportiert die
  /// Base64-Profilbilder und soll daher nicht bei jedem Tab-Wechsel laufen.
  Future<void> refreshConversations({bool force = false}) async {
    final now = _clock();
    final last = _lastConversationsRefresh;
    if (!force && last != null && now.difference(last) < conversationsTtl) {
      return;
    }
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
  }

  /// Öffnet (get-or-create) die 1:1-Konversation mit [userId]
  /// (`POST /chat/conversations`).
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

  /// Konversations-Details (`GET /chat/conversations/{id}`), z. B. beim
  /// Deep-Link oder für unbekannte Konversationen aus einem Event.
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
    notifyListeners();
    return list;
  }

  /// Sendet eine Nachricht (`POST .../messages`). Wartet auf den Server;
  /// die [clientId] macht Retries idempotent. Die Empfänger erhalten die
  /// Nachricht über den Centrifugo-Publish der API.
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

  /// Setzt den eigenen Lesestand (`POST .../read`) auf den höchsten
  /// lokal bekannten `seq` und markiert die Konversation lokal gelesen.
  ///
  /// No-op, wenn bereits alles gelesen ist — würde man ohne Guard bei jedem
  /// Echtzeit-Event aufrufen, entstünden POST-Schleifen. Ohne geladene
  /// Nachrichten gibt es nichts zu markieren.
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
        developer.log(
          'markConversationRead($conversationId) failed',
          error: e,
          stackTrace: st,
          name: 'chat_service',
        );
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
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    );
    notifyListeners();
  }

  // ─── Nachrichten-Aktionen ──────────────────────────────────────────────

  /// Bearbeitet eine Nachricht (`PATCH /chat/messages/{id}`). Nur eigener
  /// Sender, 10-Min-Fenster. Aktualisiert Inhalt und `editedAt` lokal.
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

  /// Löscht eine Nachricht für alle (`DELETE /chat/messages/{id}`). Nur
  /// eigener Sender. Setzt `deleted=true` und leert Inhalt/Payload lokal.
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _api.delete('/chat/messages/$messageId', token: await _token());
    _applyDeleted(conversationId, messageId);
    notifyListeners();
  }

  /// Sendet den Tippindikator über den Centrifugo-Publish-Proxy, debounced
  /// (max alle 3 s). Fire-and-forget — Fehler werden still ignoriert.
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

  /// Aktualisiert die Vorschau nur, wenn die Nachricht aktuell die letzte
  /// der Konversation ist (z. B. Bearbeiten/Löschen der letzten Nachricht).
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
        createdAt: c.createdAt,
        updatedAt: message.createdAt,
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

  /// Idempotenz-Schlüssel für [sendMessage]: eindeutig genug ohne
  /// zusätzliches Paket (Zeitstempel + Zufall).
  static String _generateClientId() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(0x7fffffff)}';
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _typingTimer?.cancel();
    for (final timer in _typingExpiry.values) {
      timer.cancel();
    }
    unawaited(_centrifugo.close());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
