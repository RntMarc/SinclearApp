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
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      sourceName: json['sourceName'] as String,
      sourceIcon: json['sourceIcon'] as String?,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      savedAt: json['savedAt'] as String,
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
      title: json['title'] as String,
      url: json['url'] as String,
      sourceName: json['sourceName'] as String,
      sourceIcon: json['sourceIcon'] as String?,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      publishedAt: json['publishedAt'] as String,
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
    return NewsListResponse(
      data: (json['data'] as List)
          .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
          .toList(),
      rss:
          (json['rss'] as List?)
              ?.map((e) => RssArticle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
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
