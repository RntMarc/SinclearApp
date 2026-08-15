/// Eine einzelne Story eines Nutzers.
///
/// `image` ist Base64 (ggf. mit `data:`-Präfix) und wird vom Client dekodiert.
class Story {
  final String id;
  final String image;
  final String? caption;
  final String createdAt;
  final String expiresAt;
  final bool viewed;

  const Story({
    required this.id,
    required this.image,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.viewed = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      image: json['image'] as String,
      caption: json['caption'] as String?,
      createdAt: json['createdAt'] as String,
      expiresAt: json['expiresAt'] as String,
      viewed: json['viewed'] as bool? ?? false,
    );
  }
}

/// Eine nach Autor gruppierte Gruppe des Story-Feeds.
class StoryFeedGroup {
  final String userId;
  final String displayName;
  final String? avatar;
  final List<Story> stories;

  const StoryFeedGroup({
    required this.userId,
    required this.displayName,
    this.avatar,
    required this.stories,
  });

  factory StoryFeedGroup.fromJson(Map<String, dynamic> json) {
    return StoryFeedGroup(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatar: json['avatar'] as String?,
      stories: (json['stories'] as List? ?? const [])
          .map((e) => Story.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Antwort von `GET /stories` (ungepaginiert, kein `meta`).
class StoryFeedResponse {
  final List<StoryFeedGroup> data;

  const StoryFeedResponse({required this.data});

  factory StoryFeedResponse.fromJson(Map<String, dynamic> json) {
    return StoryFeedResponse(
      data: (json['data'] as List? ?? const [])
          .map((e) => StoryFeedGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Request-Body für `POST /stories`.
class StoryCreateRequest {
  final String image;
  final String? caption;

  const StoryCreateRequest({required this.image, this.caption});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'image': image};
    if (caption != null) map['caption'] = caption;
    return map;
  }
}
