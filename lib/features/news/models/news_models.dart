class NewsArticle {
  final String id;
  final String title;
  final String url;
  final String sourceName;
  final String? sourceIcon;
  final String? imageUrl;
  final String? description;
  final String savedAt;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.url,
    required this.sourceName,
    this.sourceIcon,
    this.imageUrl,
    this.description,
    required this.savedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: _readString(json, 'id', 'ID', 'articleId'),
      title: _readString(json, 'title'),
      url: _readString(json, 'url'),
      sourceName: _readString(json, 'sourceName', 'source_name'),
      sourceIcon: _readOptionalString(json, 'sourceIcon', 'source_icon'),
      imageUrl: _readOptionalString(json, 'imageUrl', 'image_url'),
      description: _readOptionalString(json, 'description'),
      savedAt: _readString(
        json,
        'savedAt',
        'saved_at',
        'createdAt',
        'created_at',
        'publishedAt',
        'published_at',
      ),
    );
  }
}

class RssArticle {
  final String title;
  final String url;
  final String sourceName;
  final String? sourceIcon;
  final String? imageUrl;
  final String? description;
  final String publishedAt;

  const RssArticle({
    required this.title,
    required this.url,
    required this.sourceName,
    this.sourceIcon,
    this.imageUrl,
    this.description,
    required this.publishedAt,
  });

  factory RssArticle.fromJson(Map<String, dynamic> json) {
    return RssArticle(
      title: _readString(json, 'title'),
      url: _readString(json, 'url'),
      sourceName: _readString(json, 'sourceName', 'source_name'),
      sourceIcon: _readOptionalString(json, 'sourceIcon', 'source_icon'),
      imageUrl: _readOptionalString(json, 'imageUrl', 'image_url'),
      description: _readOptionalString(json, 'description'),
      publishedAt: _readString(
        json,
        'publishedAt',
        'published_at',
        'savedAt',
        'saved_at',
        'createdAt',
        'created_at',
      ),
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
      page: _readInt(json, 'page'),
      limit: _readInt(json, 'limit'),
      total: _readInt(json, 'total'),
      totalPages: _readInt(json, 'totalPages', 'total_pages'),
    );
  }

  bool get hasMore => page < totalPages;
}

class NewsListResponse {
  final List<NewsArticle> data;
  final List<RssArticle> rss;
  final PaginationMeta meta;

  const NewsListResponse({
    required this.data,
    required this.rss,
    required this.meta,
  });

  factory NewsListResponse.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as List? ?? [])
        .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
        .toList();
    final rss = (json['rss'] as List? ?? [])
        .map((e) => RssArticle.fromJson(e as Map<String, dynamic>))
        .toList();
    return NewsListResponse(
      data: data,
      rss: rss,
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : PaginationMeta(
              page: 1,
              limit: data.length,
              total: data.length,
              totalPages: 1,
            ),
    );
  }
}

class NewsItem {
  final String? id;
  final String title;
  final String url;
  final String sourceName;
  final String? sourceIcon;
  final String? imageUrl;
  final String? description;
  final DateTime date;
  final bool isFromDb;

  const NewsItem({
    this.id,
    required this.title,
    required this.url,
    required this.sourceName,
    this.sourceIcon,
    this.imageUrl,
    this.description,
    required this.date,
    required this.isFromDb,
  });

  factory NewsItem.fromDbArticle(NewsArticle article) {
    return NewsItem(
      id: article.id,
      title: article.title,
      url: article.url,
      sourceName: article.sourceName,
      sourceIcon: article.sourceIcon,
      imageUrl: article.imageUrl,
      description: article.description,
      date: DateTime.parse(article.savedAt),
      isFromDb: true,
    );
  }

  factory NewsItem.fromRssArticle(RssArticle article) {
    return NewsItem(
      title: article.title,
      url: article.url,
      sourceName: article.sourceName,
      sourceIcon: article.sourceIcon,
      imageUrl: article.imageUrl,
      description: article.description,
      date: DateTime.parse(article.publishedAt),
      isFromDb: false,
    );
  }

  NewsItem copyWith({
    String? id,
    bool? isFromDb,
    String? imageUrl,
    String? description,
  }) {
    return NewsItem(
      id: id ?? this.id,
      title: title,
      url: url,
      sourceName: sourceName,
      sourceIcon: sourceIcon,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      date: date,
      isFromDb: isFromDb ?? this.isFromDb,
    );
  }
}

class NewsVoteRequest {
  final String url;
  final String title;
  final String sourceName;
  final String? sourceIcon;

  const NewsVoteRequest({
    required this.url,
    required this.title,
    required this.sourceName,
    this.sourceIcon,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'sourceName': sourceName,
    'sourceIcon': sourceIcon,
  };
}

String _readString(Map<String, dynamic> json, String key, [
  String? second,
  String? third,
  String? fourth,
  String? fifth,
  String? sixth,
  String? seventh,
]) {
  final value = _readValue(json, [
    key,
    second,
    third,
    fourth,
    fifth,
    sixth,
    seventh,
  ]);
  if (value is String) return value;
  if (value != null) return value.toString();
  throw FormatException('Missing required string field "$key".');
}

String? _readOptionalString(Map<String, dynamic> json, String key, [
  String? second,
]) {
  final value = _readValue(json, [key, second]);
  return value?.toString();
}

int _readInt(Map<String, dynamic> json, String key, [String? second]) {
  final value = _readValue(json, [key, second]);
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  throw FormatException('Missing required int field "$key".');
}

Object? _readValue(Map<String, dynamic> json, List<String?> keys) {
  for (final key in keys) {
    if (key != null && json.containsKey(key)) return json[key];
  }
  return null;
}
