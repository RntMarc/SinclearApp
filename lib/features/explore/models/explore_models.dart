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
  final String creatorId;
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
    required this.creatorId,
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
      creatorId: json['creatorId'] as String,
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
      osmId: int.parse(json['osm_id'] as String),
      osmType: json['osm_type'] as String,
      displayName: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
      category: json['category'] as String?,
      type: json['type'] as String?,
    );
  }
}
