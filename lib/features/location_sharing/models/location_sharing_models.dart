import '../../../core/utils/date_utils.dart';

/// Sharing-Modus einer Location-Sharing-Session. Bestimmt, wie die
/// Standortpunkte von den Clients angezeigt werden (aktuelle Position vs.
/// vollständige Route).
enum SharingMode { location, route }

extension SharingModeX on SharingMode {
  String get apiValue => name;

  String get label => switch (this) {
    SharingMode.location => 'Standort',
    SharingMode.route => 'Route',
  };

  String get description => switch (this) {
    SharingMode.location => 'Nur die aktuelle Position wird angezeigt.',
    SharingMode.route => 'Position und zurückgelegte Strecke.',
  };
}

/// Ein Empfänger einer Location-Sharing-Session.
class LocationSharingRecipient {
  final String userId;
  final String displayName;
  final String? image;

  const LocationSharingRecipient({
    required this.userId,
    required this.displayName,
    this.image,
  });

  factory LocationSharingRecipient.fromJson(Map<String, dynamic> json) {
    return LocationSharingRecipient(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      image: json['image'] as String?,
    );
  }
}

/// Ein gespeicherter Standortpunkt einer Session.
class LocationSharingLocation {
  final String id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime recordedAt;
  final DateTime createdAt;

  const LocationSharingLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.recordedAt,
    required this.createdAt,
  });

  factory LocationSharingLocation.fromJson(Map<String, dynamic> json) {
    return LocationSharingLocation(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      recordedAt: parseApiDate(json['recordedAt'] as String),
      createdAt: parseApiDate(json['createdAt'] as String),
    );
  }
}

/// Eine Location-Sharing-Session.
///
/// Die Listen-Endpunkte (`GET /location-sharing/sessions`) liefern nur die
/// Basis-Felder; Detail-/Erstell-Responses füllen zusätzlich [recipients],
/// [lastLocation], [locationCount] und [integrationUrls].
class LocationSharingSession {
  final String id;
  final String token;
  final String ownerId;
  final SharingMode sharingMode;
  final int? durationSeconds;
  final int frequencySeconds;
  final bool isActive;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LocationSharingRecipient> recipients;
  final LocationSharingLocation? lastLocation;
  final int locationCount;
  final Map<String, String> integrationUrls;

  const LocationSharingSession({
    required this.id,
    required this.token,
    required this.ownerId,
    required this.sharingMode,
    this.durationSeconds,
    required this.frequencySeconds,
    required this.isActive,
    required this.startedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.recipients = const [],
    this.lastLocation,
    this.locationCount = 0,
    this.integrationUrls = const {},
  });

  factory LocationSharingSession.fromJson(Map<String, dynamic> json) {
    return LocationSharingSession(
      id: json['id'] as String,
      token: json['token'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      sharingMode: switch (json['sharingMode'] as String?) {
        'route' => SharingMode.route,
        _ => SharingMode.location,
      },
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      frequencySeconds: (json['frequencySeconds'] as num?)?.toInt() ?? 600,
      isActive: json['isActive'] as bool? ?? false,
      startedAt: parseApiDate(json['startedAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? parseApiDate(json['expiresAt'] as String)
          : null,
      createdAt: parseApiDate(json['createdAt'] as String),
      updatedAt: parseApiDate(json['updatedAt'] as String),
      recipients:
          (json['recipients'] as List<dynamic>?)
              ?.map(
                (e) => LocationSharingRecipient.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
      lastLocation: json['lastLocation'] != null
          ? LocationSharingLocation.fromJson(
              json['lastLocation'] as Map<String, dynamic>,
            )
          : null,
      locationCount: (json['locationCount'] as num?)?.toInt() ?? 0,
      integrationUrls:
          (json['integrationUrls'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          const {},
    );
  }
}

/// Eine aktive Session eines Kontakts, bei der der aktuelle Nutzer Empfänger
/// ist (`GET /location-sharing/active`).
class ActiveLocationSharing {
  final LocationSharingSession session;
  final String ownerId;
  final String ownerDisplayName;
  final String? ownerImage;
  final LocationSharingLocation? lastLocation;

  const ActiveLocationSharing({
    required this.session,
    required this.ownerId,
    required this.ownerDisplayName,
    this.ownerImage,
    this.lastLocation,
  });

  factory ActiveLocationSharing.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>? ?? const {};
    return ActiveLocationSharing(
      session: LocationSharingSession.fromJson(
        json['session'] as Map<String, dynamic>,
      ),
      ownerId: owner['id'] as String? ?? '',
      ownerDisplayName: owner['displayName'] as String? ?? '',
      ownerImage: owner['image'] as String?,
      lastLocation: json['lastLocation'] != null
          ? LocationSharingLocation.fromJson(
              json['lastLocation'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
