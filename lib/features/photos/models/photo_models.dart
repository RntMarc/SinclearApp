/// Ein einzelnes Unsplash-Foto, verlinkt von einem Sinclear-Nutzer.
///
/// `thumb` ist die kleine URL für das Grid, `regular` die mittlere für den
/// Vollbild-Viewer. Beide können null sein, wenn Unsplash keine URL liefert.
class Photo {
  final String id;
  final String? thumb;
  final String? regular;
  final int width;
  final int height;
  final String createdAt;
  final PhotoPhotographer photographer;
  final PhotoAuthor author;

  const Photo({
    required this.id,
    this.thumb,
    this.regular,
    required this.width,
    required this.height,
    required this.createdAt,
    required this.photographer,
    required this.author,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String? ?? '',
      thumb: json['thumb'] as String?,
      regular: json['regular'] as String?,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      photographer: PhotoPhotographer.fromJson(_asMap(json['photographer'])),
      author: PhotoAuthor.fromJson(_asMap(json['author'])),
    );
  }

  /// Seitenverhältnis (Breite/Höhe); fällt auf 1.0 zurück, wenn unbekannt.
  double get aspectRatio => (width > 0 && height > 0) ? width / height : 1.0;
}

/// Fotograf-Attribution gemäß Unsplash-Richtlinien.
class PhotoPhotographer {
  final String? name;
  final String? username;
  final String? url;

  const PhotoPhotographer({this.name, this.username, this.url});

  factory PhotoPhotographer.fromJson(Map<String, dynamic> json) {
    return PhotoPhotographer(
      name: json['name'] as String?,
      username: json['username'] as String?,
      url: json['url'] as String?,
    );
  }

  /// Anzeigename des Fotografen; fällt auf den Nutzernamen zurück.
  String? get displayName => name ?? username;
}

/// Der Sinclear-Nutzer, der das Foto in seinem Profil hinterlegt hat.
class PhotoAuthor {
  final String id;
  final String? displayName;
  final String? avatar;

  const PhotoAuthor({required this.id, this.displayName, this.avatar});

  factory PhotoAuthor.fromJson(Map<String, dynamic> json) {
    return PhotoAuthor(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
    );
  }
}

/// Eine Seite des Foto-Feeds inkl. Paginierungs-Meta.
class PhotoPage {
  final List<Photo> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PhotoPage({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PhotoPage.fromJson(Map<String, dynamic> json) {
    final meta = _asMap(json['meta']);
    return PhotoPage(
      data: (json['data'] as List? ?? const [])
          .map((e) => Photo.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (meta['page'] as num?)?.toInt() ?? 1,
      limit: (meta['limit'] as num?)?.toInt() ?? 0,
      total: (meta['total'] as num?)?.toInt() ?? 0,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasMore => page < totalPages;
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : const <String, dynamic>{};
