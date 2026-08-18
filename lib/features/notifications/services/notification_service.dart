// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../models/notification_item.dart';
import '../models/notification_type_preference.dart';
import 'notification_content_resolver.dart';

class NotificationService extends ChangeNotifier {
  final ApiClient _api;

  /// Bereitet rohe Benachrichtigungen (nur `type` + Relation-IDs) für die
  /// lokale Anzeige auf: lädt fehlende Daten nach und erzeugt Titel/Text.
  final NotificationContentResolver? _contentResolver;

  Timer? _pollingTimer;
  String? _lastSeen;

  /// IDs aller bereits angezeigten Benachrichtigungen dieser Session.
  /// Bewusst nicht bei `startPolling`/`stopPolling` zurückgesetzt, damit
  /// Resume/Cold-Start-Restarts keine Duplikate anzeigen.
  final Set<String> _seenIds = {};

  /// Ungelesene Benachrichtigungen, nach ID. Wahrheitsquelle ist der Server:
  /// befüllt aus Poll/Push, ersetzt durch [refreshUnread], bereinigt durch
  /// [markRead]. Wird bewusst nicht lokal persistiert.
  final Map<String, NotificationItem> _unreadById = {};

  final StreamController<List<NotificationItem>> _controller =
      StreamController<List<NotificationItem>>.broadcast();

  Stream<List<NotificationItem>> get notifications => _controller.stream;

  NotificationService({
    required ApiClient api,
    NotificationContentResolver? contentResolver,
  }) : _api = api,
       _contentResolver = contentResolver;

  void startPolling({
    required Future<String> Function() getToken,
    Duration interval = const Duration(seconds: 60),
  }) {
    if (_pollingTimer != null && _lastSeen != null) return;
    stopPolling();
    _poll(getToken);
    _pollingTimer = Timer.periodic(interval, (_) => _poll(getToken));
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _poll(Future<String> Function() getToken) async {
    try {
      final token = await getToken();
      final queryParams = <String, String>{};
      if (_lastSeen != null) {
        queryParams['since'] = _lastSeen!;
      }

      final response = await _api.get(
        '/notifications',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        token: token,
      );

      final notificationsList = response['notifications'] as List? ?? [];
      final items = notificationsList
          .map(
            (json) => NotificationItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      if (items.isNotEmpty) {
        _lastSeen = toApiDate(items.first.createdAt, withMilliseconds: true);
        final newItems = items.where((item) => _seenIds.add(item.id)).toList();

        var registryChanged = false;
        for (final item in items) {
          if (!_unreadById.containsKey(item.id)) {
            _unreadById[item.id] = item;
            registryChanged = true;
          }
        }
        if (registryChanged) notifyListeners();

        if (newItems.isEmpty) return;
        _controller.add(newItems);

        if (!kIsWeb) {
          final resolver = _contentResolver;
          if (resolver != null) {
            for (final item in newItems.take(3)) {
              await resolver.showLocal(item);
            }
          }
        }
      }
    } catch (e, st) {
      developer.log(
        'Poll error',
        error: e,
        stackTrace: st,
        name: 'notification_service',
      );
    }
  }

  Future<void> markRead(List<String> ids, {required String token}) async {
    if (ids.isEmpty) return;
    var removed = false;
    for (final id in ids) {
      removed = _unreadById.remove(id) != null || removed;
    }
    if (removed) notifyListeners();
    try {
      await _api.post('/notifications/read', body: {'ids': ids}, token: token);
    } catch (e, st) {
      // Optimistisch entfernt — beim nächsten refreshUnread() erscheint das
      // Item wieder, falls der Server das Lesen nicht übernommen hat.
      developer.log(
        'markRead error',
        error: e,
        stackTrace: st,
        name: 'notification_service',
      );
    }
  }

  /// Lädt die Benachrichtigungs-Präferenzen aller Typen
  /// (`GET /notifications/preferences`).
  Future<Map<String, NotificationTypePreference>> getPreferences({
    required String token,
  }) async {
    final response = await _api.get('/notifications/preferences', token: token);
    return NotificationPreferencesResponse.fromJson(response).data;
  }

  /// Aktualisiert nur die geänderten Typen (Bulk-Update,
  /// `PUT /notifications/preferences`). Liefert die vollständige
  /// Präferenz-Map des Servers zurück.
  Future<Map<String, NotificationTypePreference>> updatePreferences(
    List<NotificationTypePreference> changed, {
    required String token,
  }) async {
    final response = await _api.put(
      '/notifications/preferences',
      body: {'preferences': changed.map((p) => p.toRequestJson()).toList()},
      token: token,
    );
    return NotificationPreferencesResponse.fromJson(response).data;
  }

  /// Ersetzt die Unread-Registry durch den aktuellen Server-Stand
  /// (Voll-Abruf ohne `since`). Synchronisiert damit auch Lesen-Vorgänge,
  /// die auf anderen Geräten passiert sind. Bewusst getrennt vom Poll, damit
  /// der Voll-Abruf nur bei Screen-/Menü-Öffnung und Resume läuft.
  Future<void> refreshUnread({required String token}) async {
    try {
      final response = await _api.get('/notifications', token: token);
      final list = response['notifications'] as List? ?? const [];
      final items = list
          .map(
            (json) => NotificationItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      _unreadById
        ..clear()
        ..addEntries(items.map((item) => MapEntry(item.id, item)));
      notifyListeners();
    } catch (e, st) {
      developer.log(
        'refreshUnread error',
        error: e,
        stackTrace: st,
        name: 'notification_service',
      );
    }
  }

  /// Registriert eine außerhalb des Pollings empfangene Benachrichtigung
  /// (z. B. via UnifiedPush) als ungelesen.
  void registerIncoming(NotificationItem item) {
    _unreadById[item.id] = item;
    notifyListeners();
  }

  /// Leert die Unread-Registry (Logout), damit nach einem erneuten Login
  /// keine veralteten Markierungen des vorherigen Nutzers sichtbar sind.
  void clear() {
    if (_unreadById.isEmpty) return;
    _unreadById.clear();
    notifyListeners();
  }

  /// IDs aller Relationen mit der Rolle [relation] über die Unread-Registry.
  Set<String> _relationIds(String relation) {
    final ids = <String>{};
    for (final item in _unreadById.values) {
      final id = item.identifierFor(relation);
      if (id != null) ids.add(id);
    }
    return ids;
  }

  /// Gibt es ungelesene Forum-Aktivität (`forum_reply`/`forum_comment`)?
  bool get hasUnreadForumContent => _relationIds('parent_forum').isNotEmpty;

  /// IDs der Foren mit ungelesener Aktivität.
  Set<String> get unreadForumIds => _relationIds('parent_forum');

  /// IDs der Posts mit ungelesener Aktivität innerhalb eines Forums.
  Set<String> unreadPostIdsForForum(String forumId) {
    final ids = <String>{};
    for (final item in _unreadById.values) {
      if (item.identifierFor('parent_forum') != forumId) continue;
      final postId = item.identifierFor('parent_post');
      if (postId != null) ids.add(postId);
    }
    return ids;
  }

  /// Notification-IDs, die einen bestimmten Post betreffen (zum Gelesen-Markieren
  /// beim Öffnen des Post-Details).
  List<String> unreadIdsForPost(String postId) {
    final ids = <String>[];
    for (final item in _unreadById.values) {
      if (item.identifierFor('parent_post') == postId) ids.add(item.id);
    }
    return ids;
  }

  /// Notification-IDs, die eine bestimmte Story betreffen (zum Gelesen-Markieren
  /// beim Ansehen der Story).
  List<String> unreadIdsForStory(String storyId) {
    final ids = <String>[];
    for (final item in _unreadById.values) {
      if (item.identifierFor('story') == storyId) ids.add(item.id);
    }
    return ids;
  }

  /// Gibt es ungelesene Chat-Aktivität (`direct_message`)?
  bool get hasUnreadChatContent => _relationIds('conversation').isNotEmpty;

  /// IDs der Konversationen mit ungelesener Aktivität.
  Set<String> get unreadConversationIds => _relationIds('conversation');

  /// Notification-IDs, die eine bestimmte Konversation betreffen (zum
  /// Gelesen-Markieren beim Öffnen der Konversation).
  List<String> unreadIdsForConversation(String conversationId) {
    final ids = <String>[];
    for (final item in _unreadById.values) {
      if (item.identifierFor('conversation') == conversationId) {
        ids.add(item.id);
      }
    }
    return ids;
  }

  /// Gibt es ungelesene Reise-Aktivität (`trip_*`-Typen)?
  bool get hasUnreadTripContent => _relationIds('trip').isNotEmpty;

  /// IDs der Reisen mit ungelesener Aktivität.
  Set<String> get unreadTripIds => _relationIds('trip');

  /// Notification-IDs, die eine bestimmte Reise betreffen (zum
  /// Gelesen-Markieren beim Öffnen der Reise).
  List<String> unreadIdsForTrip(String tripId) {
    final ids = <String>[];
    for (final item in _unreadById.values) {
      if (item.identifierFor('trip') == tripId) ids.add(item.id);
    }
    return ids;
  }

  /// Gibt es ungelesene Aktivität bei Standalone-Events
  /// (`standalone_event_*`-Typen)?
  bool get hasUnreadStandaloneEventContent => _relationIds('event').isNotEmpty;

  /// IDs der Standalone-Events mit ungelesener Aktivität.
  Set<String> get unreadStandaloneEventIds => _relationIds('event');

  /// Notification-IDs, die ein bestimmtes Standalone-Event betreffen (zum
  /// Gelesen-Markieren beim Öffnen des Events).
  List<String> unreadIdsForStandaloneEvent(String eventId) {
    final ids = <String>[];
    for (final item in _unreadById.values) {
      if (item.identifierFor('event') == eventId) ids.add(item.id);
    }
    return ids;
  }

  @override
  void dispose() {
    stopPolling();
    _controller.close();
    super.dispose();
  }
}
