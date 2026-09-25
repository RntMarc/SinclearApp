import 'dart:async';
import 'dart:convert';

// ignore_for_file: prefer_initializing_formals

import 'package:centrifuge/centrifuge.dart' as centrifuge;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:logging/logging.dart';

import '../../auth/services/auth_service.dart';

final _log = Logger('chat.realtime');

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

  /// Letzte Fehlermeldung je Channel (für Log-Deduplizierung).
  final Map<String, String> _lastSubscribeError = {};

  /// Roh-Events aus allen Channels. Der Consumer filtert nach Channel.
  final _events = StreamController<CentrifugoEvent>.broadcast();

  /// `true`, sobald eine Verbindung aufgebaut ist.
  bool _connected = false;
  bool get connected => _connected;

  /// Nach dem ersten Connect `true`. Für Reconnect-Erkennung.
  bool _everConnected = false;

  /// Feuert bei jeder Wiederverbindung (nicht beim ersten Connect).
  final _reconnectedController = StreamController<void>.broadcast();

  /// Stream der bei Reconnect feuert (nach initialem Connect).
  Stream<void> get onReconnected => _reconnectedController.stream;

  /// Publikationen (`message_created`/`message_edited`/`message_deleted`/
  /// `read`/`typing`) samt Channel.
  Stream<CentrifugoEvent> get events => _events.stream;

  /// Ob aktuell eine Subscription für [conversationId] existiert.
  bool isSubscribed(String conversationId) =>
      _subscriptions.containsKey(conversationId);

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
      _log.warning('subscribe($conversationId) failed', e, st);
    }
  }

  /// Entfernt die Subscription des Channels aus der Registry.
  Future<void> unsubscribe(String conversationId) async {
    final sub = _subscriptions.remove(conversationId);
    final client = _client;
    if (sub == null || client == null) return;
    try {
      await client.removeSubscription(sub);
      _log.info('Unsubscribed from chat:$conversationId');
    } catch (e, st) {
      _log.warning('unsubscribe($conversationId) failed', e, st);
    }
  }

  /// Sendet ein Typing-Event über den Publish-Proxy (fire-and-forget).
  Future<void> publishTyping(String conversationId, bool typing) async {
    final sub = _subscriptions[conversationId];
    if (sub == null) return;
    try {
      await sub.publish(_encode({'typing': typing}));
    } catch (e, st) {
      _log.warning('publishTyping($conversationId) failed', e, st);
    }
  }

  /// Sendet eine Reaktion über den Publish-Proxy.
  ///
  /// [add] ist explizit (true = setzen, false = entfernen), damit ein
  /// serverseitiger Retry idempotent bleibt. Fehler (z. B. Rate-Limit,
  /// ungültiges Emoji) werden nach oben gereicht; die Subscription muss
  /// bestehen.
  Future<void> publishReaction(
    String conversationId,
    String messageId,
    String emoji,
    bool add,
  ) async {
    final sub = _subscriptions[conversationId];
    if (sub == null) {
      throw StateError('Nicht mit chat:$conversationId verbunden');
    }
    await sub.publish(
      _encode({
        'reaction': {'messageId': messageId, 'emoji': emoji, 'add': add},
      }),
    );
  }

  /// Sendet eine Nachricht (inkl. optionaler Antwort) über den Publish-Proxy.
  ///
  /// Fehler (Validierung, Rate-Limit) werden nach oben gereicht; die
  /// Subscription muss bestehen. Die Nachricht kommt über das
  /// `message_created`-Event zurück (inkl. Sender).
  Future<void> publishMessage(
    String conversationId,
    String clientId,
    String content,
    String? replyToMessageId,
  ) async {
    final sub = _subscriptions[conversationId];
    if (sub == null) {
      throw StateError('Nicht mit chat:$conversationId verbunden');
    }
    await sub.publish(
      _encode({
        'message': {
          'clientId': clientId,
          'type': 'text',
          'content': content,
          'replyToMessageId': ?replyToMessageId,
        },
      }),
    );
  }

  /// Stellt die Verbindung ins Vordergrund (Resubscribe läuft automatisch).
  Future<void> connect() async {
    try {
      await _ensureConnected();
    } catch (e, st) {
      _log.warning('connect failed', e, st);
    }
  }

  /// Trennt die Verbindung bei App-Hintergrund. Subscription-Registry bleibt
  /// erhalten und wird beim nächsten [connect] automatisch wiederhergestellt.
  Future<void> disconnect() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.disconnect();
      _log.info('Disconnected');
    } catch (e, st) {
      _log.warning('disconnect failed', e, st);
    }
  }

  /// Logout: alle Subscriptions entfernen und Client schließen.
  Future<void> close() async {
    final client = _client;
    _client = null;
    _subscriptions.clear();
    _lastSubscribeError.clear();
    _connected = false;
    unawaited(_reconnectedController.close());
    if (client == null) return;
    try {
      await client.close();
    } catch (e, st) {
      _log.warning('close failed', e, st);
    }
  }

  // ─── Interne Verbindungslogik ────────────────────────────────────────

  /// Seriellisiert: verhindert parallele Client-Erstellung durch
  /// mehrfach gleichzeitige [_ensureConnected]-Aufrufe.
  Future<void>? _connecting;

  Future<void> _ensureConnected() async {
    final pending = _connecting;
    if (pending != null) {
      await pending;
      return;
    }
    _connecting = _doConnect();
    try {
      await _connecting;
    } finally {
      _connecting = null;
    }
  }

  Future<void> _doConnect() async {
    var client = _client;
    if (client == null) {
      _log.info('Creating Centrifugo client');
      final token = await _auth.getCentrifugoToken();
      if (token.url.isEmpty) {
        throw StateError('Centrifugo-URL fehlt in der API-Antwort');
      }
      _log.info('Centrifugo URL: ${token.url}');
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
      _log.info('Connecting to Centrifugo...');
      await client.connect();
    }
  }

  void _listenLifecycle(centrifuge.Client client) {
    client.connected.listen((_) {
      if (_everConnected) {
        _log.info('Reconnected to Centrifugo');
        _reconnectedController.add(null);
      } else {
        _log.info('Connected to Centrifugo');
      }
      _everConnected = true;
      _connected = true;
    });
    client.disconnected.listen((event) {
      _log.warning(
        'Disconnected from Centrifugo: code=${event.code} '
        'reason=${event.reason}',
      );
      _connected = false;
    });
    client.error.listen((event) {
      _log.severe('Centrifugo client error: ${event.error}');
    });
  }

  // ─── Subscriptions ──────────────────────────────────────────────────

  void _addSubscription(centrifuge.Client client, String conversationId) {
    final channel = 'chat:$conversationId';
    if (_subscriptions.containsKey(conversationId)) return;
    // joinLeave aktiviert Join/Leave-Push für Presence im Chat-Channel.
    final sub = client.newSubscription(
      channel,
      centrifuge.SubscriptionConfig(joinLeave: true),
    );
    _subscriptions[conversationId] = sub;

    sub.publication.listen((event) {
      final data = decodePayload(event.data);
      if (data == null) return;
      // Client-Publishes (z. B. Typing) tragen den Absender nur im
      // Publication-Info — der Publish-Proxy entfernt ein `userId` aus dem
      // Payload. Der Server hängt `info` an client-seitige Publikationen an.
      final publisher = event.info?.user;
      final enriched = withPublisherUserId(data, publisher);
      _log.fine(
        'Publication on $channel: type=${data['type']} '
        'publisher=$publisher',
      );
      _events.add(
        CentrifugoEvent(conversationId: conversationId, data: enriched),
      );
    });
    sub.join.listen((event) {
      _events.add(
        CentrifugoEvent(
          conversationId: conversationId,
          data: {
            'type': 'presence_join',
            'client': event.client,
            'user': event.user,
          },
        ),
      );
    });
    sub.leave.listen((event) {
      _events.add(
        CentrifugoEvent(
          conversationId: conversationId,
          data: {
            'type': 'presence_leave',
            'client': event.client,
            'user': event.user,
          },
        ),
      );
    });
    sub.subscribed.listen((event) {
      _lastSubscribeError.remove(channel);
      _log.info(
        'Subscribed to $channel '
        '(wasRecovering=${event.wasRecovering}, '
        'recovered=${event.recovered}, '
        'recoverable=${event.recoverable})',
      );
      if (event.wasRecovering && !event.recovered) {
        _log.warning(
          'Recovery gap on $channel – consumer must reload via REST',
        );
        _events.add(
          CentrifugoEvent(
            conversationId: conversationId,
            data: const {'type': 'recovered_gap'},
          ),
        );
      }
      unawaited(_emitPresenceSnapshot(sub, conversationId));
    });
    sub.unsubscribed.listen((event) {
      _log.warning(
        'Unsubscribed from $channel: code=${event.code} '
        'reason=${event.reason}',
      );
      _subscriptions.remove(conversationId);
    });
    sub.error.listen((event) {
      final msg = event.error.toString();
      if (_lastSubscribeError[channel] == msg) return;
      _lastSubscribeError[channel] = msg;
      _log.warning('Subscription error on $channel: $msg');
    });
    sub.subscribe();
    _log.info('Subscribe initiated for $channel');
  }

  /// Liest nach dem Subscribe die aktuelle Presence des Channels aus.
  ///
  /// Der Snapshot ersetzt clientseitig den Presence-Stand (Selbst- und
  /// Fremd-Clients). Join/Leave-Deltas kommen danach über [sub.join]/[leave].
  Future<void> _emitPresenceSnapshot(
    centrifuge.Subscription sub,
    String conversationId,
  ) async {
    try {
      final result = await sub.presence();
      _events.add(
        CentrifugoEvent(
          conversationId: conversationId,
          data: {
            'type': 'presence_snapshot',
            'clients': {
              for (final entry in result.clients.entries)
                entry.key: entry.value.user,
            },
          },
        ),
      );
    } catch (e, st) {
      _log.warning('presence($conversationId) failed', e, st);
    }
  }

  // ─── Payload-Kodierung ──────────────────────────────────────────────

  static List<int> _encode(Map<String, dynamic> data) =>
      utf8.encode(jsonEncode(data));

  /// Dekodiert einen Publication-Payload. Öffentlich für Tests.
  @visibleForTesting
  static Map<String, dynamic>? decodePayload(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<String, dynamic>) return decoded;
      _log.warning('Unexpected payload type: ${decoded.runtimeType}');
      return null;
    } catch (e, st) {
      _log.severe('Payload decode failed (${bytes.length} bytes)', e, st);
      return null;
    }
  }

  @visibleForTesting
  static List<int> encodePayload(Map<String, dynamic> data) => _encode(data);

  /// Hängt den [publisher] als `userId` an [data], wenn dieses keinen eigenen
  /// `userId` enthält.
  ///
  /// Client-Publishes (z. B. Typing) liefern den Absender nur über das
  /// Centrifugo-Publication-Info; der Publish-Proxy entfernt ein `userId` aus
  /// dem Payload. Ohne diese Ergänzung ist der Empfänger nicht bestimmbar.
  @visibleForTesting
  static Map<String, dynamic> withPublisherUserId(
    Map<String, dynamic> data,
    String? publisher,
  ) {
    if (publisher == null || publisher.isEmpty || data['userId'] != null) {
      return data;
    }
    return {...data, 'userId': publisher};
  }
}

/// Eine Publication aus einem Chat-Channel, bereits JSON-dekodiert.
class CentrifugoEvent {
  final String conversationId;
  final Map<String, dynamic> data;

  const CentrifugoEvent({required this.conversationId, required this.data});
}
