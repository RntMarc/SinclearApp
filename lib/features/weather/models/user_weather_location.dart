class UserWeatherLocation {
  final String id;
  final String name;
  final String? slug;
  final double lat;
  final double lon;
  final String source;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  const UserWeatherLocation({
    required this.id,
    required this.name,
    this.slug,
    required this.lat,
    required this.lon,
    this.source = 'nominatim',
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserWeatherLocation.fromJson(Map<String, dynamic> json) {
    return UserWeatherLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      source: json['source'] as String? ?? 'nominatim',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'name': name,
        'slug': slug,
        'lat': lat,
        'lon': lon,
        'source': source,
        'sortOrder': sortOrder,
      };

  /// Convert to the local SavedLocation format for backward compatibility.
  dynamic toSavedLocationJson() => {
        'name': name,
        'slug': slug,
        'lat': lat,
        'lon': lon,
        'source': source,
      };
}
