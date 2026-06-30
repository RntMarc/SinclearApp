enum FeedbackStatus {
  submitted,
  planned,
  next,
  inProgress,
  done,
  cancelled,
  rejected,
  later;

  String get label {
    switch (this) {
      case FeedbackStatus.submitted:
        return 'Eingereicht';
      case FeedbackStatus.planned:
        return 'Geplant';
      case FeedbackStatus.next:
        return 'Nächstes Feature';
      case FeedbackStatus.inProgress:
        return 'In Entwicklung';
      case FeedbackStatus.done:
        return 'Umgesetzt';
      case FeedbackStatus.cancelled:
        return 'Abgesagt';
      case FeedbackStatus.rejected:
        return 'Abgelehnt';
      case FeedbackStatus.later:
        return 'Später';
    }
  }

  static FeedbackStatus fromJson(String value) {
    return FeedbackStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FeedbackStatus.submitted,
    );
  }

  String toJson() => name;

  int get sortIndex {
    switch (this) {
      case FeedbackStatus.done:
        return 0;
      case FeedbackStatus.inProgress:
        return 1;
      case FeedbackStatus.next:
        return 2;
      case FeedbackStatus.planned:
        return 3;
      case FeedbackStatus.later:
        return 4;
      case FeedbackStatus.submitted:
        return 5;
      case FeedbackStatus.rejected:
        return 6;
      case FeedbackStatus.cancelled:
        return 7;
    }
  }
}

class FeedbackSuggestion {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final FeedbackStatus status;
  final int upvoteCount;
  final bool hasVoted;
  final String createdAt;
  final String updatedAt;

  const FeedbackSuggestion({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.status,
    required this.upvoteCount,
    required this.hasVoted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackSuggestion.fromJson(Map<String, dynamic> json) {
    return FeedbackSuggestion(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: FeedbackStatus.fromJson(json['status'] as String),
      upvoteCount: json['upvoteCount'] as int,
      hasVoted: json['hasVoted'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class FeedbackSuggestionListResponse {
  final List<FeedbackSuggestion> data;
  final PaginationMeta meta;

  const FeedbackSuggestionListResponse({
    required this.data,
    required this.meta,
  });

  factory FeedbackSuggestionListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final items = (json['data'] as List)
        .map((e) => FeedbackSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] != null
        ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            page: 1,
            limit: items.length,
            total: items.length,
            totalPages: 1,
          );
    return FeedbackSuggestionListResponse(data: items, meta: meta);
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

class FeedbackSuggestionCreateRequest {
  final String title;
  final String? description;

  const FeedbackSuggestionCreateRequest({
    required this.title,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'title': title};
    if (description != null) map['description'] = description;
    return map;
  }
}

class FeedbackStatusUpdateRequest {
  final FeedbackStatus status;

  const FeedbackStatusUpdateRequest({required this.status});

  Map<String, dynamic> toJson() => {'status': status.toJson()};
}
