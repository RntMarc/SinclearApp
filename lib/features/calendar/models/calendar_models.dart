class UserBrief {
  final String id;
  final String displayName;
  final String? image;

  const UserBrief({required this.id, required this.displayName, this.image});

  factory UserBrief.fromJson(Map<String, dynamic> json) {
    return UserBrief(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      image: json['image'] as String?,
    );
  }
}

class CalendarEvent {
  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final int visibility;
  final List<UserBrief> participants;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarEvent({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.visibility,
    this.participants = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['startTime'] as String).toLocal(),
      endTime: DateTime.parse(json['endTime'] as String).toLocal(),
      visibility: json['visibility'] as int,
      participants:
          (json['participants'] as List?)
              ?.map((e) => UserBrief.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'visibility': visibility,
    };
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

class CalendarEventListResponse {
  final List<CalendarEvent> data;
  final PaginationMeta meta;

  const CalendarEventListResponse({required this.data, required this.meta});

  factory CalendarEventListResponse.fromJson(Map<String, dynamic> json) {
    final events = (json['data'] as List)
        .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] != null
        ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            page: 1,
            limit: events.length,
            total: events.length,
            totalPages: 1,
          );
    return CalendarEventListResponse(data: events, meta: meta);
  }
}

class CalendarEventDetailResponse {
  final CalendarEvent data;

  const CalendarEventDetailResponse({required this.data});

  factory CalendarEventDetailResponse.fromJson(Map<String, dynamic> json) {
    return CalendarEventDetailResponse(
      data: CalendarEvent.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
