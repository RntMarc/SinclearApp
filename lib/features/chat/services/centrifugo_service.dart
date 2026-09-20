import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

// ignore_for_file: prefer_initializing_formals

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../auth/services/auth_service.dart';

/// Echtzeit-Transport für den Chat über einen Centrifugo-Server.
///
/// Kapselt das `centrifuge`-SDK: Verbindungsaufbau, Token-Refresh,
/// Channel-Subscriptions und das Lesen/Senden von Publication-Payloads.
/// Enthält bewusst keine Chat-Domänenlogik — die landet in [ChatService].
///
/// Die API ist die Quelle der Wahrheit: WebSocket-URL und Connection-Token
/// kommen aus [AuthService.getCentrifugoToken]. Subscription-Tokens sind
/// nicht nötig (der Server nutzt den Subscribe-Proxy).
class CentrifugoService {
  CentrifugoService({required AuthService auth}) : _auth = auth;

  final AuthService _auth;

  centrifuge.Client? _client;

  /// Bereits abonnierte Channels (conversationId → Subscription).
  final Map<String, centrifuge.Subscription> _subscriptions = {};

  /// Roh-Events aus allen Channels. Der Consumer filtert nach Channel.
  final _events = StreamController<CentrifugoEvent>.broadcast();

  /// `true`, sobald eine Verbindung aufgebaut ist.
  bool _connected = false;
  bool get connected => _connected;

  /// Publikationen (`message_created`/`message_edited`/`message_deleted`/
  /// `read`/`typing`) samt Channel.
  Stream<CentrifugoEvent> get events => _events.stream;

  /// Verbindet, falls noch nicht geschehen, und abonniert [conversationId].
  ///
  /// Fehler werden geloggt, nicht geworfen: Chat läuft ohne Echtzeit weiter.
  Future<void> subscribe(String conversationId) async {
    if (_subscriptions.containsKey(conversationId)) return;
    try {
      await _ensureConnected();
      final client = _client;
      if (client == null) return;
      _addSubscription(client, conversationId);
    } catch (e, st) {
      developer.log(
        'Centrifugo subscribe($conversationId) failed',
        error: e,
        stackTrace: st,
        name: 'centrifugo',
      );
    }
  }

  /// Entfernt die Subscription des Channels aus der Registry.
  Future<void> unsubscribe(String conversationId) async {
    final sub = _subscriptions.remove(conversationId);
    final client = _client;
    if (sub == null || client == null) return;
    try {
      await client.removeSubscription(sub);
    } catch (e, st) {
      developer.log(
        'Centrifugo unsubscribe($conversationId) failed',
        error: e,
        stackTrace: st,
        name: 'centrifugo',
      );
    }
  }

  /// Sendet ein Typing-Event über den Publish-Proxy (fire-and-forget).
  Future<void> publishTyping(String conversationId, bool typing) async {
    final sub = _subscriptions[conversationId];
    if (sub == null) return;
    try {
      await sub.publish(_encode({'typing': typing}));
    } catch (e, st) {
      developer.log(
        'Centrifugo publishTyping($conversationId) failed',
        error: e,
        stackTrace: st,
        name: 'centrifugo',
      );
    }
  }

  /// Stellt die Verbindung ins Vordergrund (Resubscribe läuft automatisch).
  Future<void> connect() async {
    try {
      await _ensureConnected();
    } catch (e, st) {
      developer.log(
        'Centrifugo connect failed',
        error: e,
        stackTrace: st,
        name: 'centrifugo',
      );
    }
  }

  /// Trennt die Verbindung bei App-Hintergrund. Subscription-Registry bleibt
  /// erhalten und wird beim nächsten [connect] automatisch wiederhergestellt.
  Future<void> disconnect() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.disconnect();
    } catch (e, st) {
      developer.log(
        'Centrifugo disconnect failed',
        error: e,
        stackTrace: st,
        name: 'centrifugo',
      );
    }
  }

  /// Logout: alle Subscriptions entfernen und Client schließen.
  Future<void> close() async {
    final client = _client;
    _client = null;
    _subscriptions.clear();
    _connected = false;
    if (client == null) return;
    try {
      await client.close();
    } catch (e, st) {
      developer.log(
        'Centrifugo close failed',
        error: e,
        stackTrace: st,
        name: 'centrifugo',
      );
    }
  }

  Future<void> _ensureConnected() async {
    var client = _client;
    if (client == null) {
      final token = await _auth.getCentrifugoToken();
      if (token.url.isEmpty) {
        throw StateError('Centrifugo-URL fehlt in der API-Antwort');
      }
      client = centrifuge.createClient(
        token.url,
        centrifuge.ClientConfig(
          token: token.token,
          getToken: (_) async => (await _auth.getCentrifugoToken()).token,
        ),
      );
      _listenLifecycle(client);
      _client = client;
    }
    if (client.state == centrifuge.State.disconnected) {
      await client.connect();
    }
  }

  void _listenLifecycle(centrifuge.Client client) {
    client.connected.listen((_) {
      _connected = true;
    });
    client.disconnected.listen((_) {
      _connected = false;
    });
    client.error.listen((event) {
      developer.log(
        'Centrifugo client error: ${event.error}',
        name: 'centrifugo',
      );
    });
  }

  void _addSubscription(centrifuge.Client client, String conversationId) {
    final channel = 'chat:$conversationId';
    final sub = client.newSubscription(channel);
    sub.publication.listen((event) {
      final data = decodePayload(event.data);
      if (data != null) {
        _events.add(
          CentrifugoEvent(conversationId: conversationId, data: data),
        );
      }
    });
    sub.subscribed.listen((event) {
      // Recovery-Lücke -> Consumer muss per REST nachladen.
      if (event.wasRecovering && !event.recovered) {
        _events.add(
          CentrifugoEvent(
            conversationId: conversationId,
            data: const {'type': 'recovered_gap'},
          ),
        );
      }
    });
    sub.subscribe();
    _subscriptions[conversationId] = sub;
  }

  static List<int> _encode(Map<String, dynamic> data) =>
      utf8.encode(jsonEncode(data));

  /// Dekodiert einen Publication-Payload. Öffentlich für Tests.
  @visibleForTesting
  static Map<String, dynamic>? decodePayload(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e, st) {
      developer.log(
        'Centrifugo payload decode failed',
        error: e,
        stackTrace: st,
        name: 'centrifugo',
      );
      return null;
    }
  }

  @visibleForTesting
  static List<int> encodePayload(Map<String, dynamic> data) => _encode(data);
}

/// Eine Publication aus einem Chat-Channel, bereits JSON-dekodiert.
class CentrifugoEvent {
  final String conversationId;
  final Map<String, dynamic> data;

  const CentrifugoEvent({required this.conversationId, required this.data});
}
