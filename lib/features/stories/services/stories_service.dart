import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../models/stories_models.dart';

/// API-Zugriff auf Stories plus sessionweiter Feed-Zustand.
///
/// Der Feed und die Gesehen-Markierungen leben hier (und damit länger als
/// die Stories-Leiste), damit die Leiste beim Scrollen aus dem Sichtfeld
/// oder beim Zurückkehren zum Dashboard nicht neu lädt, sondern sofort aus
/// dem Zustand rendert. Aktualisiert wird nur über den Dashboard-Zyklus:
/// App-Start, 5-Minuten-Timer, Pull-to-Refresh und App-Resume
/// (`DashboardController.refreshAll` → [refreshFeed]).
class StoriesService extends ChangeNotifier {
  final ApiClient _api;
  final AuthService _auth;

  List<StoryFeedGroup>? _groups;
  Object? _error;

  /// In dieser Session gesehene Story-IDs (lokal markiert oder vom Server
  /// als gesehen geliefert). Wird nie geleert, damit Ringe nicht
  /// zurückblinken, wenn der Server eine lokale Markierung noch nicht kennt.
  final Set<String> _viewedIds = {};

  StoriesService({required this._api, required this._auth});

  /// Zuletzt geladener Feed; `null` vor dem ersten erfolgreichen Abruf.
  List<StoryFeedGroup>? get groups => _groups;

  /// Fehler des letzten Abrufs; `null` bei Erfolg.
  Object? get error => _error;

  Future<String> _token() => _auth.getAccessToken();

  /// Roher Feed-Abruf (z. B. vom Story-Deep-Link, der bewusst frisch lädt).
  Future<StoryFeedResponse> feed() async {
    final data = await _api.get('/stories', token: await _token());
    return StoryFeedResponse.fromJson(data);
  }

  /// Lädt den Feed in den sessionweiten Zustand. Wirft nicht — Fehler
  /// landen in [error], die letzten Daten bleiben sichtbar.
  Future<void> refreshFeed() async {
    try {
      final response = await feed();
      _groups = response.data;
      _error = null;
      _viewedIds.addAll([
        for (final group in response.data)
          for (final story in group.stories)
            if (story.viewed) story.id,
      ]);
    } catch (e) {
      _error = e;
    }
    notifyListeners();
  }

  /// Wurde die Story in dieser Session bereits gesehen?
  bool isViewed(String storyId) => _viewedIds.contains(storyId);

  /// Markiert die Story als gesehen und meldet es idempotent an die API.
  Future<void> markViewed(String id) async {
    if (!_viewedIds.add(id)) return;
    notifyListeners();
    try {
      await _api.post('/stories/$id/view', token: await _token());
    } catch (_) {
      // Idempotent; der nächste Abruf liefert den Stand erneut.
    }
  }

  Future<void> create({required String image, String? caption}) async {
    await _api.post(
      '/stories',
      body: StoryCreateRequest(image: image, caption: caption).toJson(),
      token: await _token(),
    );
  }

  Future<void> delete(String id) async {
    await _api.delete('/stories/$id', token: await _token());
  }

  /// Einzelne Story mit viewCount und Autor-Info laden.
  Future<StoryDetail> getStory(String id) async {
    final data = await _api.get('/stories/$id', token: await _token());
    return StoryDetailResponse.fromJson(data).data;
  }

  /// Viewer-Liste einer Story laden (nur für Ersteller oder Admin).
  /// Wirft bei 403 wenn der Nutzer nicht berechtigt ist.
  Future<List<StoryViewerItem>> getViewers(String id) async {
    final data = await _api.get('/stories/$id/viewers', token: await _token());
    return StoryViewersResponse.fromJson(data).data;
  }
}
