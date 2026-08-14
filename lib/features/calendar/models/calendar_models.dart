import '../../../core/utils/date_utils.dart';

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
  final String? creatorDisplayName;
  final String? creatorImage;
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
    this.creatorDisplayName,
    this.creatorImage,
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
      creatorDisplayName: json['creatorDisplayName'] as String?,
      creatorImage: json['creatorImage'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: parseApiDate(json['startTime'] as String),
      endTime: parseApiDate(json['endTime'] as String),
      visibility: json['visibility'] as int,
      participants:
          (json['participants'] as List?)
              ?.map((e) => UserBrief.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: parseApiDate(json['createdAt'] as String),
      updatedAt: parseApiDate(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startTime': toApiDate(startTime),
      'endTime': toApiDate(endTime),
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

/// Die Quelltypen des kombinierten Kalender-Feeds (`GET /calendar/all`).
///
/// Der Feed aggregiert echte Kalender-Events, Reise-Events, Reisen,
/// Geburtstage und ÖPNV-Fahrten zu einer flachen, nach `startTime`
/// aufsteigend sortierten Liste.
class CalendarEntryType {
  static const calendarEvent = 'calendar_event';
  static const travelEvent = 'travel_event';
  static const trip = 'trip';
  static const birthday = 'birthday';
  static const ptJourney = 'pt_journey';

  const CalendarEntryType._();
}

/// Ein Eintrag des kombinierten Kalender-Feeds (`GET /calendar/all`).
///
/// [detail] enthält das typspezifische Roh-Objekt; die Detail-Screens laden
/// ihre Daten selbst per ID nach. Bei Geburtstagen ist [id] zusammengesetzt
/// (`Vorkommensdatum + Nutzer-ID`) — die Nutzer-ID steckt in `detail.userId`.
class CalendarEntry {
  final String type;
  final String id;
  final String? title;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool allDay;
  final Map<String, dynamic> detail;

  const CalendarEntry({
    required this.type,
    required this.id,
    this.title,
    this.startTime,
    this.endTime,
    this.allDay = false,
    this.detail = const {},
  });

  /// Eindeutiger Schlüssel über Typ und ID — IDs sind nur pro Quelle
  /// eindeutig (Geburtstags-IDs kollidieren nicht, aber Reisen und
  /// Reise-Events teilen sich den ID-Raum nicht zwangsläufig).
  String get key => '$type:$id';

  /// Die ID, die der Detail-Screen des Typs braucht: für Geburtstage die
  /// Nutzer-ID aus `detail.userId`, sonst [id]. `null`, wenn der
  /// Geburtstags-Eintrag keine Nutzer-ID enthält.
  String? get targetId {
    if (type != CalendarEntryType.birthday) return id;
    final userId = detail['userId'];
    return userId is String && userId.isNotEmpty ? userId : null;
  }

  factory CalendarEntry.fromJson(Map<String, dynamic> json) {
    final rawStart = json['startTime'] as String?;
    final rawEnd = json['endTime'] as String?;
    final rawDetail = json['detail'];
    return CalendarEntry(
      type: json['type'] as String,
      id: json['id'] as String,
      title: json['title'] as String?,
      startTime: rawStart == null ? null : parseApiDate(rawStart),
      endTime: rawEnd == null ? null : parseApiDate(rawEnd),
      allDay: json['allDay'] == true,
      detail: rawDetail is Map<String, dynamic> ? rawDetail : const {},
    );
  }

  /// Wandelt ein echtes Kalender-Event in einen Feed-Eintrag um — für neu
  /// erstellte Events, ohne Server-Roundtrip.
  factory CalendarEntry.fromCalendarEvent(CalendarEvent event) {
    return CalendarEntry(
      type: CalendarEntryType.calendarEvent,
      id: event.id,
      title: event.title,
      startTime: event.startTime,
      endTime: event.endTime,
    );
  }
}

/// Antwort von `GET /calendar/all`: flache, sortierte Eintragsliste.
///
/// Der Endpunkt ist nicht paginiert; [truncated] zeigt an, dass mindestens
/// eine Quelle im angefragten Zeitraum die 500er-Grenze erreicht hat.
class CalendarAllResponse {
  final List<CalendarEntry> data;
  final bool truncated;

  const CalendarAllResponse({required this.data, this.truncated = false});

  factory CalendarAllResponse.fromJson(Map<String, dynamic> json) {
    final entries = (json['data'] as List)
        .map((e) => CalendarEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'];
    return CalendarAllResponse(
      data: entries,
      truncated: meta is Map<String, dynamic> && meta['truncated'] == true,
    );
  }
}
