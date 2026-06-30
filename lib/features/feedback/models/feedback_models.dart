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
        return 'Abgebrochen';
      case FeedbackStatus.rejected:
        return 'Abgelehnt';
      case FeedbackStatus.later:
        return 'Später';
    }
  }

  static FeedbackStatus fromJson(String value) {
    switch (value) {
      case 'in_progress':
        return FeedbackStatus.inProgress;
      default:
        return FeedbackStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => FeedbackStatus.submitted,
        );
    }
  }

  String toJson() {
    switch (this) {
      case FeedbackStatus.inProgress:
        return 'in_progress';
      default:
        return name;
    }
  }

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
  final int commentCount;
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
    this.commentCount = 0,
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
      commentCount: json['commentCount'] as int? ?? 0,
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

class FeedbackComment {
  final String id;
  final String suggestionId;
  final String userId;
  final String? parentId;
  final String? text;
  final String createdAt;
  final String updatedAt;
  final List<FeedbackComment> children;

  const FeedbackComment({
    required this.id,
    required this.suggestionId,
    required this.userId,
    this.parentId,
    this.text,
    required this.createdAt,
    required this.updatedAt,
    this.children = const [],
  });

  factory FeedbackComment.fromJson(Map<String, dynamic> json) {
    return FeedbackComment(
      id: json['id'] as String,
      suggestionId: json['suggestionId'] as String,
      userId: json['userId'] as String,
      parentId: json['parentId'] as String?,
      text: json['text'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => FeedbackComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get isDeleted => text == null;
}

class FeedbackCommentListResponse {
  final List<FeedbackComment> data;
  final int total;

  const FeedbackCommentListResponse({required this.data, required this.total});

  factory FeedbackCommentListResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List)
        .map((e) => FeedbackComment.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>?;
    return FeedbackCommentListResponse(
      data: items,
      total: meta?['total'] as int? ?? items.length,
    );
  }
}

class FeedbackCommentCreateRequest {
  final String text;
  final String? parentId;

  const FeedbackCommentCreateRequest({required this.text, this.parentId});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'text': text};
    if (parentId != null) map['parentId'] = parentId;
    return map;
  }
}

class FeedbackCommentUpdateRequest {
  final String text;

  const FeedbackCommentUpdateRequest({required this.text});

  Map<String, dynamic> toJson() => {'text': text};
}

class BugReportRequest {
  final String text;
  final String? version;
  final int? buildNumber;
  final String? image;

  const BugReportRequest({
    required this.text,
    this.version,
    this.buildNumber,
    this.image,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'text': text};
    if (version != null) map['version'] = version;
    if (buildNumber != null) map['buildNumber'] = buildNumber;
    if (image != null) map['image'] = image;
    return map;
  }
}

class BugReportResponse {
  final bool sent;

  const BugReportResponse({required this.sent});

  factory BugReportResponse.fromJson(Map<String, dynamic> json) {
    return BugReportResponse(sent: json['data']['sent'] as bool);
  }
}
