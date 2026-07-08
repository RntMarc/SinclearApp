class LocationSharingSession {
  final String id;
  final String ownerId;
  final int durationSeconds;
  final int frequencySeconds;
  final bool isActive;
  final String startedAt;
  final String expiresAt;
  final String createdAt;
  final String updatedAt;

  const LocationSharingSession({
    required this.id,
    required this.ownerId,
    required this.durationSeconds,
    required this.frequencySeconds,
    required this.isActive,
    required this.startedAt,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationSharingSession.fromJson(Map<String, dynamic> json) {
    return LocationSharingSession(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      frequencySeconds: (json['frequencySeconds'] as num).toInt(),
      isActive: json['isActive'] as bool,
      startedAt: json['startedAt'] as String,
      expiresAt: json['expiresAt'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class LocationRecipient {
  final String userId;
  final String displayName;
  final String? image;

  const LocationRecipient({
    required this.userId,
    required this.displayName,
    this.image,
  });

  factory LocationRecipient.fromJson(Map<String, dynamic> json) {
    return LocationRecipient(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      image: json['image'] as String?,
    );
  }
}

class LocationSharingLocation {
  final String id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String recordedAt;
  final String createdAt;

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
      recordedAt: json['recordedAt'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}

class LocationSharingSessionDetail {
  final String id;
  final String token;
  final String ownerId;
  final int durationSeconds;
  final int frequencySeconds;
  final bool isActive;
  final String startedAt;
  final String expiresAt;
  final String createdAt;
  final String updatedAt;
  final List<LocationRecipient> recipients;
  final LocationSharingLocation? lastLocation;
  final Map<String, String> integrationUrls;

  const LocationSharingSessionDetail({
    required this.id,
    required this.token,
    required this.ownerId,
    required this.durationSeconds,
    required this.frequencySeconds,
    required this.isActive,
    required this.startedAt,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    required this.recipients,
    this.lastLocation,
    this.integrationUrls = const {},
  });

  factory LocationSharingSessionDetail.fromJson(Map<String, dynamic> json) {
    return LocationSharingSessionDetail(
      id: json['id'] as String,
      token: (json['token'] as String?) ?? '',
      ownerId: json['ownerId'] as String,
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      frequencySeconds: (json['frequencySeconds'] as num).toInt(),
      isActive: json['isActive'] as bool,
      startedAt: json['startedAt'] as String,
      expiresAt: json['expiresAt'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      recipients: (json['recipients'] as List<dynamic>)
          .map((e) => LocationRecipient.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastLocation: json['lastLocation'] != null
          ? LocationSharingLocation.fromJson(json['lastLocation'] as Map<String, dynamic>)
          : null,
      integrationUrls: json['integrationUrls'] != null
          ? (json['integrationUrls'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as String))
          : const {},
    );
  }
}

class LocationSharingActiveSession {
  final LocationSharingSession session;
  final LocationSharingActiveOwner owner;
  final LocationSharingLocation? lastLocation;

  const LocationSharingActiveSession({
    required this.session,
    required this.owner,
    this.lastLocation,
  });

  factory LocationSharingActiveSession.fromJson(Map<String, dynamic> json) {
    return LocationSharingActiveSession(
      session: LocationSharingSession.fromJson(json['session'] as Map<String, dynamic>),
      owner: LocationSharingActiveOwner.fromJson(json['owner'] as Map<String, dynamic>),
      lastLocation: json['lastLocation'] != null
          ? LocationSharingLocation.fromJson(json['lastLocation'] as Map<String, dynamic>)
          : null,
    );
  }
}

class LocationSharingActiveOwner {
  final String id;
  final String displayName;
  final String? image;

  const LocationSharingActiveOwner({
    required this.id,
    required this.displayName,
    this.image,
  });

  factory LocationSharingActiveOwner.fromJson(Map<String, dynamic> json) {
    return LocationSharingActiveOwner(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      image: json['image'] as String?,
    );
  }
}

class CreateSessionRequest {
  final List<String> recipientIds;
  final int durationSeconds;
  final int frequencySeconds;

  const CreateSessionRequest({
    required this.recipientIds,
    required this.durationSeconds,
    this.frequencySeconds = 600,
  });

  Map<String, dynamic> toJson() => {
    'recipient_ids': recipientIds,
    'duration_seconds': durationSeconds,
    'frequency_seconds': frequencySeconds,
  };
}

class UpdateSessionRequest {
  final int? durationSeconds;
  final bool? isActive;

  const UpdateSessionRequest({this.durationSeconds, this.isActive});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (durationSeconds != null) map['duration_seconds'] = durationSeconds;
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}

class SendLocationRequest {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String recordedAt;

  const SendLocationRequest({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (accuracy != null) 'accuracy': accuracy,
    'recordedAt': recordedAt,
  };
}
