import '../../../core/utils/youtube_helper.dart';
import '../../../core/utils/spotify_helper.dart';

class Forum {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final int memberCount;
  final String createdAt;
  final String updatedAt;

  const Forum({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Forum.fromJson(Map<String, dynamic> json) {
    return Forum(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      memberCount: json['memberCount'] as int,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class ForumDetail extends Forum {
  final bool isMember;
  final bool notificationsEnabled;

  const ForumDetail({
    required super.id,
    required super.name,
    super.description,
    super.image,
    required super.memberCount,
    required super.createdAt,
    required super.updatedAt,
    required this.isMember,
    required this.notificationsEnabled,
  });

  factory ForumDetail.fromJson(Map<String, dynamic> json) {
    return ForumDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      image: json['image'] as String?,
      memberCount: json['memberCount'] as int,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      isMember: json['isMember'] as bool,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
    );
  }
}

class ForumListResponse {
  final List<Forum> data;
  final PaginationMeta meta;

  const ForumListResponse({required this.data, required this.meta});

  factory ForumListResponse.fromJson(Map<String, dynamic> json) {
    final forums = (json['data'] as List)
        .map((e) => Forum.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(
      json['meta'] as Map<String, dynamic>,
    );
    return ForumListResponse(data: forums, meta: meta);
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

class ForumMember {
  final String id;
  final String forumId;
  final String userId;
  final String? displayName;
  final String? image;
  final bool notificationsEnabled;
  final String createdAt;

  const ForumMember({
    required this.id,
    required this.forumId,
    required this.userId,
    this.displayName,
    this.image,
    required this.notificationsEnabled,
    required this.createdAt,
  });

  factory ForumMember.fromJson(Map<String, dynamic> json) {
    return ForumMember(
      id: json['id'] as String,
      forumId: json['forumId'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      image: json['image'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] as String,
    );
  }
}

class ForumMemberListResponse {
  final List<ForumMember> data;

  const ForumMemberListResponse({required this.data});

  factory ForumMemberListResponse.fromJson(Map<String, dynamic> json) {
    final members = (json['data'] as List)
        .map((e) => ForumMember.fromJson(e as Map<String, dynamic>))
        .toList();
    return ForumMemberListResponse(data: members);
  }
}

class FeedPost {
  final String id;
  final String forumId;
  final String userId;
  final String type;
  final Map<String, dynamic> content;
  final int upvoteCount;
  final int commentCount;
  final bool hasVoted;
  final String createdAt;
  final String updatedAt;

  const FeedPost({
    required this.id,
    required this.forumId,
    required this.userId,
    required this.type,
    required this.content,
    required this.upvoteCount,
    required this.commentCount,
    required this.hasVoted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'] as String,
      forumId: json['forumId'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      content: json['content'] as Map<String, dynamic>,
      upvoteCount: (json['upvoteCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      hasVoted: json['hasVoted'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  String? get text => content['text'] as String?;
  String? get title => content['title'] as String?;

  /// Raw URL list as provided by the API.
  List get _rawUrls {
    final raw = content['urls'];
    if (raw == null) return const [];
    return raw as List;
  }

  /// True when the API sent plain-string URLs (web post type).
  bool get _hasStringUrls =>
      _rawUrls.isNotEmpty && _rawUrls.first is String;

  /// Music/video posts: list of {platform, url} objects.
  List<MusicUrl> get urls {
    if (_hasStringUrls) return const [];
    return _rawUrls
        .map((e) => MusicUrl.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Web posts: list of plain URL strings.
  List<String> get webUrls {
    if (!_hasStringUrls) return const [];
    return _rawUrls.cast<String>().toList();
  }

  /// YouTube video IDs extracted from web URLs.
  List<String> get youtubeIds =>
      webUrls
          .map(YoutubeHelper.extractVideoId)
          .whereType<String>()
          .toList();

  /// Spotify IDs (track/album/playlist) extracted from web URLs.
  List<SpotifyItem> get spotifyItems =>
      webUrls.map(SpotifyHelper.parseUrl).whereType<SpotifyItem>().toList();

  /// Web URLs that are neither YouTube nor Spotify.
  List<String> get genericUrls => webUrls
      .where((u) => YoutubeHelper.extractVideoId(u) == null)
      .where((u) => SpotifyHelper.parseUrl(u) == null)
      .toList();

  // --- Getters for music/video posts (List<MusicUrl>) ---

  /// YouTube video IDs extracted from MusicUrl objects (video posts).
  List<String> get youtubeVideoIds => urls
      .where((u) => u.platform.toLowerCase().contains('youtube'))
      .map((u) => YoutubeHelper.extractVideoId(u.url))
      .whereType<String>()
      .toList();

  /// Spotify items extracted from MusicUrl objects (music posts).
  List<SpotifyItem> get spotifyMusicItems => urls
      .where((u) => u.platform.toLowerCase().contains('spotify'))
      .map((u) => SpotifyHelper.parseUrl(u.url))
      .whereType<SpotifyItem>()
      .toList();

  /// MusicUrl objects that are neither YouTube nor Spotify.
  List<MusicUrl> get genericMusicUrls {
    final lower = urls
        .where((u) => !u.platform.toLowerCase().contains('youtube'))
        .where((u) => !u.platform.toLowerCase().contains('spotify'))
        .toList();
    return lower;
  }
}

class MusicUrl {
  final String platform;
  final String url;

  const MusicUrl({required this.platform, required this.url});

  factory MusicUrl.fromJson(Map<String, dynamic> json) {
    return MusicUrl(
      platform: json['platform'] as String,
      url: json['url'] as String,
    );
  }
}

class FeedPostListResponse {
  final List<FeedPost> data;
  final PaginationMeta meta;

  const FeedPostListResponse({required this.data, required this.meta});

  factory FeedPostListResponse.fromJson(Map<String, dynamic> json) {
    final posts = (json['data'] as List)
        .map((e) => FeedPost.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(
      json['meta'] as Map<String, dynamic>,
    );
    return FeedPostListResponse(data: posts, meta: meta);
  }
}

class FeedPostComment {
  final String id;
  final String postId;
  final String userId;
  final String? parentId;
  final String? text;
  final String createdAt;
  final String updatedAt;
  final List<FeedPostComment> children;

  const FeedPostComment({
    required this.id,
    required this.postId,
    required this.userId,
    this.parentId,
    this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.children,
  });

  bool get isDeleted => text == null;

  factory FeedPostComment.fromJson(Map<String, dynamic> json) {
    return FeedPostComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      userId: json['userId'] as String,
      parentId: json['parentId'] as String?,
      text: json['text'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => FeedPostComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class FeedPostCommentListResponse {
  final List<FeedPostComment> data;
  final int total;

  const FeedPostCommentListResponse({required this.data, required this.total});

  factory FeedPostCommentListResponse.fromJson(Map<String, dynamic> json) {
    final comments = (json['data'] as List)
        .map((e) => FeedPostComment.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = json['meta'] != null
        ? (json['meta']['total'] as num).toInt()
        : comments.length;
    return FeedPostCommentListResponse(data: comments, total: total);
  }
}

class FeedPostCreateRequest {
  final String? type;
  final Map<String, dynamic> content;

  const FeedPostCreateRequest({this.type, required this.content});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'content': content};
    if (type != null) map['type'] = type;
    return map;
  }
}
