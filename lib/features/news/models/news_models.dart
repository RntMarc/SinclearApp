class NewsArticle {
  final String id;
  final String title;
  final String url;
  final String sourceName;
  final String? sourceIcon;
  final String savedAt;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.url,
    required this.sourceName,
    this.sourceIcon,
    required this.savedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      sourceName: json['sourceName'] as String,
      sourceIcon: json['sourceIcon'] as String?,
      savedAt: json['savedAt'] as String,
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
  final PaginationMeta meta;

  const NewsListResponse({required this.data, required this.meta});

  factory NewsListResponse.fromJson(Map<String, dynamic> json) {
    return NewsListResponse(
      data: (json['data'] as List)
          .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
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
