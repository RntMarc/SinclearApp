// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/chat_models.dart';

/// Hält den Chat-Zustand: Konversationsliste, Nachrichten je Konversation
/// und den Sync-Loop über `GET /chat/sync` (Short Polling, adaptiv).
///
/// Polling läuft nur, solange mindestens ein UI-Teilnehmer aktiv ist
/// ([registerActive]/[unregisterActive], z. B. Chat-Tab oder geöffnete
/// Konversation). Chat-Liste und offene Konversation gelten dabei gleich als
/// aktiv und nutzen den schnellen 2-s-Takt; ohne aktiven Teilnehmer stoppt
/// der Sync komplett (Hintergrund).
class ChatService extends ChangeNotifier with WidgetsBindingObserver {
  ChatService({
    required ApiClient api,
    required AuthService auth,
    this.conversationsTtl = const Duration(seconds: 60),
    DateTime Function() clock = DateTime.now,
  }) : _api = api,
       _auth = auth,
       _clock = clock {
    WidgetsBinding.instance.addObserver(this);
  }

  final ApiClient _api;
  final AuthService _auth;

  /// Mindestabstand zwischen zwei vollen Konversationslisten-Abrufen.
  /// Verhindert, dass jeder Tab-Wechsel die Liste (inkl. Base64-Profilbilder)
  /// erneut vom Server lädt.
  final Duration conversationsTtl;

  final DateTime Function() _clock;

  final List<ChatConversation> _conversations = [];
  final Map<String, List<DirectMessage>> _messages = {};

  /// Zeitpunkt des letzten erfolgreichen [refreshConversations].
  DateTime? _lastConversationsRefresh;

  /// Höchster gesehener Event-seq (Cursor für `after`).
  int? _lastEventSeq;
  Timer? _syncTimer;
  bool _syncInFlight = false;
  int _activeCount = 0;
  Map<String, List<String>> _typingUsers = {};
  Timer? _typingTimer;
  bool _typingSent = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  /// Nur wenn die App im Vordergrund ist (resumed) wird gepollt.
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

  bool get syncing => _syncInFlight;

  /// Tippzustand des Gegenübers (aus Sync-Poll).
  /// Map: conversationId → [userId, …].
  Map<String, List<String>> get typingUsers => _typingUsers;

  /// Chat-UI sichtbar: Startet/erhält den Sync-Loop (ref-counted, damit
  /// Tab und Konversations-Screen sich nicht gegenseitig stoppen).
  void registerActive() {
    _activeCount++;
    _restartSyncTimer();
  }

  void unregisterActive() {
    if (_activeCount > 0) _activeCount--;
    _restartSyncTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _restartSyncTimer();
  }

  // ─── REST-API ─────────────────────────────────────────────────────────

  /// Vollständige Konversationsliste (`GET /chat/conversations`).
  ///
  /// Überspringt den Abruf, wenn die Liste innerhalb von [conversationsTtl]
  /// zuletzt geladen wurde (außer [force]); die Sync-Zusammenfassung hält
  /// Unread und Vorschau derweil aktuell. Der volle Abruf transportiert die
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
  /// Deep-Link oder für unbekannte Konversationen aus dem Sync.
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
  /// die [clientId] macht Retries idempotent.
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
  /// No-op, wenn bereits alles gelesen ist — der Screen ruft dies bei
  /// jedem Sync auf, ohne Guard würde das POST- und notify-Schleifen
  /// erzeugen. Ohne geladene Nachrichten gibt es nichts zu markieren.
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
        // Optimistisch: Der nächste Sync spiegelt den echten Serverstand.
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
    final list = _messages[conversationId];
    if (list != null) {
      final idx = list.indexWhere((m) => m.id == messageId);
      if (idx >= 0) {
        final old = list[idx];
        final deleted = DirectMessage(
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
        list[idx] = deleted;
        _updatePreviewIfCurrent(conversationId, deleted);
      }
    }
    notifyListeners();
  }

  /// Sendet den Tippindikator (`POST …/typing`), debounced (max alle 3 s).
  /// Fire-and-forget — Fehler werden still ignoriert.
  void sendTyping(String conversationId) {
    if (_typingSent) return;
    _typingSent = true;
    unawaited(_sendTypingRequest(conversationId));
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () => _typingSent = false);
  }

  Future<void> _sendTypingRequest(String conversationId) async {
    try {
      await _api.post(
        '/chat/conversations/$conversationId/typing',
        body: {'typing': true},
        token: await _token(),
      );
    } catch (_) {}
  }

  // ─── Sync-Loop ────────────────────────────────────────────────────────

  void _restartSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
    if (_activeCount == 0 || !_foreground) return;
    unawaited(_pollSync());
    const interval = Duration(seconds: 2);
    _syncTimer = Timer.periodic(interval, (_) => unawaited(_pollSync()));
  }

  /// Ein Sync-Durchlauf; bei `meta.hasMore` direkt nachziehen.
  Future<void> _pollSync() async {
    if (_syncInFlight || _activeCount == 0 || !_foreground) return;
    _syncInFlight = true;
    try {
      var after = _lastEventSeq;
      while (true) {
        final query = <String, String>{'limit': '200'};
        if (after != null) query['after'] = '$after';
        final response = await _api.get(
          '/chat/sync',
          queryParams: query,
          token: await _token(),
        );
        final sync = ChatSyncResponse.fromJson(response);
        _applySync(sync);
        _lastEventSeq = sync.seq;
        after = sync.seq;
        if (!sync.hasMore || _activeCount == 0 || !_foreground) break;
      }
    } catch (e, st) {
      developer.log(
        'Chat sync failed',
        error: e,
        stackTrace: st,
        name: 'chat_service',
      );
    } finally {
      _syncInFlight = false;
    }
  }

  void _applySync(ChatSyncResponse sync) {
    var changed = false;
    for (final summary in sync.conversations) {
      final index = _conversations.indexWhere(
        (c) => c.id == summary.conversationId,
      );
      if (index >= 0) {
        final c = _conversations[index];
        _conversations[index] = ChatConversation(
          id: c.id,
          type: c.type,
          name: c.name,
          otherUser: c.otherUser,
          lastMessage: c.lastMessage,
          unreadCount: summary.unreadCount,
          lastSeenAt: summary.lastSeenAt ?? c.lastSeenAt,
          lastReadSeq: c.lastReadSeq,
          otherLastReadSeq: summary.otherLastReadSeq ?? c.otherLastReadSeq,
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
        );
        changed = true;
      } else {
        // Neue Konversation (z. B. vom Gegenüber erstellt): Details
        // nachladen — die Sync-Zusammenfassung enthält keine Anzeige-Daten.
        unawaited(_ensureConversation(summary.conversationId));
      }
    }
    for (final event in sync.events) {
      final message = event.message;
      if (message == null) continue;
      _upsertMessage(event.conversationId, message);
      if (event.type == 'message_created') {
        _updatePreview(event.conversationId, message);
      }
      changed = true;
    }
    _typingUsers = sync.typing;
    if (changed) notifyListeners();
  }

  Future<void> _ensureConversation(String id) async {
    try {
      await loadConversation(id);
    } catch (e, st) {
      developer.log(
        'Loading unknown conversation $id failed',
        error: e,
        stackTrace: st,
        name: 'chat_service',
      );
    }
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

  /// Aktualisiert die Vorschau (letzte Nachricht) der Konversation —
  /// die Sync-Zusammenfassung enthält keine `lastMessage`-Daten.
  void _updatePreview(String conversationId, DirectMessage message) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index < 0) return;
    final c = _conversations[index];
    _conversations[index] = ChatConversation(
      id: c.id,
      type: c.type,
      name: c.name,
      otherUser: c.otherUser,
      lastMessage: ChatMessageSummary(
        content: message.content,
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
    _conversations[index] = ChatConversation(
      id: c.id,
      type: c.type,
      name: c.name,
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
    _sortConversations();
  }

  /// Idempotenz-Schlüssel für [sendMessage]: eindeutig genug ohne
  /// zusätzliches Paket (Zeitstempel + Zufall).
  static String _generateClientId() {
    final random = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(0x7fffffff)}';
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}
