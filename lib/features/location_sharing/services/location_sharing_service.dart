import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/services/auth_service.dart';
import '../models/location_sharing_models.dart';

// ignore_for_file: prefer_initializing_formals

/// Client für die Location-Sharing-API.
///
/// Die App teilt selbst keinen Standort (kein `POST .../locations`). Sie
/// verwaltet eigene Sessions (Erstellen/Beenden) und zeigt die Standorte
/// anderer Kontakte an (Empfänger-Sicht).
class LocationSharingService {
  final ApiClient _api;
  final AuthService _auth;

  LocationSharingService({required ApiClient api, required AuthService auth})
    : _api = api,
      _auth = auth;

  Future<String> _token() => _auth.getAccessToken();

  /// Erstellt eine neue Session und gibt das Detail inkl. Token und
  /// Drittanbieter-URLs zurück.
  Future<LocationSharingSession> createSession({
    required List<String> recipientIds,
    int? durationSeconds,
    SharingMode sharingMode = SharingMode.location,
  }) async {
    final body = <String, dynamic>{
      'recipient_ids': recipientIds,
      'sharing_mode': sharingMode.apiValue,
    };
    if (durationSeconds != null) body['duration_seconds'] = durationSeconds;

    final data = await _api.post(
      '/location-sharing/sessions',
      body: body,
      token: await _token(),
    );
    return LocationSharingSession.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }

  /// Eigene aktive Sessions des aktuellen Nutzers.
  Future<List<LocationSharingSession>> listOwnSessions() async {
    final data = await _api.get(
      '/location-sharing/sessions',
      token: await _token(),
    );
    final items = data['data'] as List<dynamic>? ?? const [];
    return items
        .map((e) => LocationSharingSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LocationSharingSession> getSession(String id) async {
    final data = await _api.get(
      '/location-sharing/sessions/$id',
      token: await _token(),
    );
    return LocationSharingSession.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }

  /// Beendet eine eigene Session.
  Future<void> stopSession(String id) async {
    await _api.delete('/location-sharing/sessions/$id', token: await _token());
  }

  /// Aktive Sessions von Kontakten, bei denen der aktuelle Nutzer Empfänger
  /// ist. Enthält Besitzer-Informationen und die letzte Position.
  Future<List<ActiveLocationSharing>> listActiveContacts() async {
    final data = await _api.get(
      '/location-sharing/active',
      token: await _token(),
    );
    final items = data['data'] as List<dynamic>? ?? const [];
    return items
        .map((e) => ActiveLocationSharing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Standort-Verlauf einer Session. Mit [since] werden nur neue Standorte
  /// zurückgegeben (Polling).
  Future<List<LocationSharingLocation>> getLocations(
    String id, {
    DateTime? since,
  }) async {
    final params = <String, String>{};
    if (since != null) {
      params['since'] = toApiDate(since);
    }
    final data = await _api.get(
      '/location-sharing/sessions/$id/locations',
      queryParams: params.isEmpty ? null : params,
      token: await _token(),
    );
    final items = data['data'] as List<dynamic>? ?? const [];
    return items
        .map((e) => LocationSharingLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
