import '../../../core/utils/date_utils.dart';

/// Prüft, ob die API eine direkte Löschung durch den Ersteller noch erlaubt:
/// nur innerhalb von 30 Minuten nach dem Erstellen (siehe explore/readme.md).
///
/// Die API erzwingt das Fenster serverseitig; dieser Check ist nur eine
/// UI-Schätzung, bei Abweichungen antwortet `DELETE /explore/{id}` mit
/// `edit_window_expired`.
bool canDeleteWithinWindow(String createdAt, {DateTime? now}) {
  final created = parseApiDate(createdAt);
  final reference = now ?? DateTime.now();
  return reference.difference(created) <= const Duration(minutes: 30);
}

class ExplorePlace {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? osmId;
  final String? osmType;
  final String? phone;
  final String? website;
  final String? email;
  final String? openingHours;
  final String? cuisine;

  /// Nur bei authentifizierten Aufrufen gesetzt; die öffentlichen Endpunkte
  /// blenden `creatorId` für anonyme Nutzer aus.
  final String? creatorId;
  final String createdAt;
  final String lastUpdated;
  final double? distance;
  final double? avgRating;
  final String? bookmarkedAt;

  const ExplorePlace({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.address,
    this.latitude,
    this.longitude,
    this.osmId,
    this.osmType,
    this.phone,
    this.website,
    this.email,
    this.openingHours,
    this.cuisine,
    this.creatorId,
    required this.createdAt,
    required this.lastUpdated,
    this.distance,
    this.avgRating,
    this.bookmarkedAt,
  });

  factory ExplorePlace.fromJson(Map<String, dynamic> json) {
    return ExplorePlace(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      osmId: json['osmId'] as int?,
      osmType: json['osmType'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
      openingHours: json['openingHours'] as String?,
      cuisine: json['cuisine'] as String?,
      creatorId: json['creatorId'] as String?,
      createdAt: json['createdAt'] as String,
      lastUpdated: json['lastUpdated'] as String,
      distance: (json['distance'] as num?)?.toDouble(),
      avgRating: (json['avgRating'] as num?)?.toDouble(),
      bookmarkedAt: json['bookmarkedAt'] as String?,
    );
  }
}

class PaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  bool get hasMore => page < totalPages;
}

class ExploreListResponse {
  final List<ExplorePlace> data;
  final PaginationMeta meta;

  const ExploreListResponse({required this.data, required this.meta});

  factory ExploreListResponse.fromJson(Map<String, dynamic> json) {
    final places = (json['data'] as List)
        .map((e) => ExplorePlace.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] != null
        ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            page: 1,
            limit: places.length,
            total: places.length,
            totalPages: 1,
          );
    return ExploreListResponse(data: places, meta: meta);
  }
}

class CreatePlaceRequest {
  final int osmId;
  final String osmType;

  const CreatePlaceRequest({required this.osmId, required this.osmType});

  Map<String, dynamic> toJson() => {'osmId': osmId, 'osmType': osmType};
}

class Review {
  final String id;
  final String placeId;
  final String userId;
  final int rating;
  final String? comment;
  final String createdAt;

  const Review({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      placeId: json['placeId'] as String,
      userId: json['userId'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}

class ReviewListResponse {
  final List<Review> data;
  final PaginationMeta meta;

  const ReviewListResponse({required this.data, required this.meta});

  factory ReviewListResponse.fromJson(Map<String, dynamic> json) {
    final reviews = (json['data'] as List)
        .map((e) => Review.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] != null
        ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            page: 1,
            limit: reviews.length,
            total: reviews.length,
            totalPages: 1,
          );
    return ReviewListResponse(data: reviews, meta: meta);
  }
}

class CreateReviewRequest {
  final int rating;
  final String? comment;

  const CreateReviewRequest({required this.rating, this.comment});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'rating': rating};
    if (comment != null) map['comment'] = comment;
    return map;
  }
}

class UpdateReviewRequest {
  final int? rating;
  final String? comment;

  const UpdateReviewRequest({this.rating, this.comment});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (rating != null) map['rating'] = rating;
    if (comment != null) {
      map['comment'] = comment;
    } else {
      map['comment'] = null;
    }
    return map;
  }
}

class NominatimResult {
  final int osmId;
  final String osmType;
  final String displayName;
  final double lat;
  final double lon;
  final String? category;
  final String? type;

  const NominatimResult({
    required this.osmId,
    required this.osmType,
    required this.displayName,
    required this.lat,
    required this.lon,
    this.category,
    this.type,
  });

  factory NominatimResult.fromJson(Map<String, dynamic> json) {
    return NominatimResult(
      osmId: (json['osm_id'] as num).toInt(),
      osmType: json['osm_type'] as String,
      displayName: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
      category: json['category'] as String?,
      type: json['type'] as String?,
    );
  }
}

class ExploreSubmission {
  final String id;
  final String userId;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final String? photo;
  final String? mapLink;
  final String? website;
  final int? rating;
  final String? comment;
  final String? note;
  final String status;
  final String? adminNote;
  final String? targetPlaceId;
  final String createdAt;
  final String updatedAt;

  const ExploreSubmission({
    required this.id,
    required this.userId,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.photo,
    this.mapLink,
    this.website,
    this.rating,
    this.comment,
    this.note,
    required this.status,
    this.adminNote,
    this.targetPlaceId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExploreSubmission.fromJson(Map<String, dynamic> json) {
    return ExploreSubmission(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      photo: json['photo'] as String?,
      mapLink: json['mapLink'] as String?,
      website: json['website'] as String?,
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
      note: json['note'] as String?,
      status: json['status'] as String,
      adminNote: json['adminNote'] as String?,
      targetPlaceId: json['targetPlaceId'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  bool get isPending => status == 'pending';
}

class ExploreSubmissionListResponse {
  final List<ExploreSubmission> data;
  final PaginationMeta meta;

  const ExploreSubmissionListResponse({required this.data, required this.meta});

  factory ExploreSubmissionListResponse.fromJson(Map<String, dynamic> json) {
    final submissions = (json['data'] as List)
        .map((e) => ExploreSubmission.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] != null
        ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            page: 1,
            limit: submissions.length,
            total: submissions.length,
            totalPages: 1,
          );
    return ExploreSubmissionListResponse(data: submissions, meta: meta);
  }
}

class ExploreSubmissionCreateRequest {
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final String? photo;
  final String? mapLink;
  final String? website;
  final int rating;
  final String? comment;
  final String? note;

  const ExploreSubmissionCreateRequest({
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.photo,
    this.mapLink,
    this.website,
    required this.rating,
    this.comment,
    this.note,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
    };
    if (address != null) map['address'] = address;
    if (photo != null) map['photo'] = photo;
    if (mapLink != null) map['mapLink'] = mapLink;
    if (website != null) map['website'] = website;
    if (comment != null) map['comment'] = comment;
    if (note != null) map['note'] = note;
    return map;
  }
}

class ExploreSubmissionUpdateRequest {
  final String? name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? photo;
  final String? mapLink;
  final String? website;
  final int? rating;
  final String? comment;
  final String? note;

  const ExploreSubmissionUpdateRequest({
    this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.photo,
    this.mapLink,
    this.website,
    this.rating,
    this.comment,
    this.note,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (address != null) map['address'] = address;
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (photo != null) map['photo'] = photo;
    if (mapLink != null) map['mapLink'] = mapLink;
    if (website != null) map['website'] = website;
    if (rating != null) map['rating'] = rating;
    if (comment != null) map['comment'] = comment;
    if (note != null) map['note'] = note;
    return map;
  }
}
