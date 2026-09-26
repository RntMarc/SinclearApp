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

/// Ein Kalender-Event im zeitzonen-bewussten API-Format.
///
/// Getaktet (`allDay == false`): `startAt`/`endAt` sind absolute
/// UTC-Instants (RFC 3339 vom Server), `timezone` ist die gemeinte
/// IANA-Zeitzone.
/// Ganztägig (`allDay == true`): `startDate`/`endDate` sind zivile Tage
/// (inklusives Ende), ebenfalls mit `timezone`.
class CalendarEvent {
  final String id;
  final String creatorId;
  final String? creatorDisplayName;
  final String? creatorImage;
  final String title;
  final String? description;
  final bool allDay;
  final String timezone;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? startDate;
  final DateTime? endDate;
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
    this.allDay = false,
    this.timezone = 'UTC',
    this.startAt,
    this.endAt,
    this.startDate,
    this.endDate,
    required this.visibility,
    this.participants = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Sortierbarer Startzeitpunkt: getaktet der Instant, ganztägig der
  /// Tagesbeginn des zivilen Starttags.
  DateTime get startInstant {
    if (allDay) {
      final date = startDate ?? endDate;
      if (date == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime(date.year, date.month, date.day);
    }
    return startAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Sortierbarer Endzeitpunkt (ganztägig = Tagesende des zivilen Endtags).
  DateTime get endInstant {
    if (allDay) {
      final date = endDate ?? startDate;
      if (date == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime(date.year, date.month, date.day, 23, 59);
    }
    return endAt ?? startInstant;
  }

  /// Tag, an dem das Event im Kalender erscheint (lokal beim Nutzer).
  DateTime get displayDay {
    final instant = startInstant.toLocal();
    return DateTime(instant.year, instant.month, instant.day);
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final rawStartAt = json['startAt'] as String?;
    final rawEndAt = json['endAt'] as String?;
    final rawStartDate = json['startDate'] as String?;
    final rawEndDate = json['endDate'] as String?;
    return CalendarEvent(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String,
      creatorDisplayName: json['creatorDisplayName'] as String?,
      creatorImage: json['creatorImage'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      allDay: json['allDay'] == true || json['allDay'] == 1,
      timezone: json['timezone'] as String? ?? 'UTC',
      startAt: (rawStartAt == null || rawStartAt.isEmpty)
          ? null
          : parseApiInstant(rawStartAt),
      endAt: (rawEndAt == null || rawEndAt.isEmpty)
          ? null
          : parseApiInstant(rawEndAt),
      startDate: (rawStartDate == null || rawStartDate.isEmpty)
          ? null
          : parseApiDateOnly(rawStartDate),
      endDate: (rawEndDate == null || rawEndDate.isEmpty)
          ? null
          : parseApiDateOnly(rawEndDate),
      visibility: json['visibility'] as int,
      participants:
          (json['participants'] as List?)
              ?.map((e) => UserBrief.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: parseApiInstant(json['createdAt'] as String),
      updatedAt: parseApiInstant(json['updatedAt'] as String),
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
/// Geburtstage und ÖPNV-Fahrten zu einer flachen, chronologisch
/// sortierten Liste.
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
/// Getaktete Einträge tragen `startAt`/`endAt` (UTC-Instants) und `timezone`,
/// ganztägige `startDate`/`endDate` (zivile Tage) und `timezone`.
/// [detail] enthält das typspezifische Roh-Objekt; die Detail-Screens laden
/// ihre Daten selbst per ID nach. Bei Geburtstagen ist [id] zusammengesetzt
/// (`Vorkommensdatum + Nutzer-ID`) — die Nutzer-ID steckt in `detail.userId`.
class CalendarEntry {
  final String type;
  final String id;
  final String? title;
  final bool allDay;
  final String timezone;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic> detail;

  const CalendarEntry({
    required this.type,
    required this.id,
    this.title,
    this.allDay = false,
    this.timezone = 'UTC',
    this.startAt,
    this.endAt,
    this.startDate,
    this.endDate,
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

  /// Sortier-/Gruppierschlüssel: getaktet der Instant, ganztägig der
  /// Tagesbeginn des zivilen Starttags. `null`, wenn kein Start vorliegt.
  DateTime? get sortInstant {
    if (allDay) {
      final date = startDate;
      return date == null ? null : DateTime(date.year, date.month, date.day);
    }
    return startAt;
  }

  /// Tag, an dem der Eintrag im Kalender erscheint (lokale Sicht des Nutzers).
  DateTime? get displayDay {
    if (allDay) {
      final date = startDate;
      return date == null ? null : DateTime(date.year, date.month, date.day);
    }
    final local = startAt?.toLocal();
    return local == null ? null : DateTime(local.year, local.month, local.day);
  }

  factory CalendarEntry.fromJson(Map<String, dynamic> json) {
    final rawStartAt = json['startAt'] as String?;
    final rawEndAt = json['endAt'] as String?;
    final rawStart = json['startDate'] as String?;
    final rawEnd = json['endDate'] as String?;
    return CalendarEntry(
      type: json['type'] as String,
      id: json['id'] as String,
      title: json['title'] as String?,
      allDay: json['allDay'] == true || json['allDay'] == 1,
      timezone: json['timezone'] as String? ?? 'UTC',
      startAt: (rawStartAt == null || rawStartAt.isEmpty)
          ? null
          : parseApiInstant(rawStartAt),
      endAt: (rawEndAt == null || rawEndAt.isEmpty)
          ? null
          : parseApiInstant(rawEndAt),
      startDate: (rawStart == null || rawStart.isEmpty)
          ? null
          : parseApiDateOnly(rawStart),
      endDate: (rawEnd == null || rawEnd.isEmpty)
          ? null
          : parseApiDateOnly(rawEnd),
      detail: rawDetail(json['detail']),
    );
  }

  /// Wandelt ein echtes Kalender-Event in einen Feed-Eintrag um — für neu
  /// erstellte Events, ohne Server-Roundtrip.
  factory CalendarEntry.fromCalendarEvent(CalendarEvent event) {
    return CalendarEntry(
      type: CalendarEntryType.calendarEvent,
      id: event.id,
      title: event.title,
      allDay: event.allDay,
      timezone: event.timezone,
      startAt: event.startAt,
      endAt: event.endAt,
      startDate: event.startDate,
      endDate: event.endDate,
    );
  }
}

Map<String, dynamic> rawDetail(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

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
