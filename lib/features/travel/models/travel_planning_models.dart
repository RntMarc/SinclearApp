import '../../../core/utils/date_utils.dart';

/// Modelle der Reiseplanung (API-Prefix `/trips/planning`, Phase 2).
///
/// Spiegelt die OpenAPI-Schemas `TravelPlanningTrip`,
/// `TravelPlanningTripDetail`, `TravelPlanTopic`, `TravelPlanMember`,
/// `TravelPlanDateOption`, `TravelPlanTransport`,
/// `TravelPlanAccommodationOption` und `TravelPlanEventSuggestion`.
///
/// Die Zeitfelder folgen der zeitzonen-bewussten Konvention (siehe
/// `AGENTS.md`): getaktete Einträge als RFC-3339-Instant (`startAt`/`endAt`),
/// ganztägige als zivile Tage (`startDate`/`endDate`) plus `timezone`.
/// `allDay` ist die einzige Quelle dafür, welche Feldgruppe gilt. Planungen
/// ohne festen Termin liefern alle Zeitfelder als `null`.

/// Feste Topics der drei Planungsphasen (Schlüssel wie in der API).
class PlanningPhase {
  const PlanningPhase._();

  static const participants = 'participants';
  static const travel = 'travel';
  static const program = 'program';

  /// Feste Reihenfolge der Phasen.
  static const order = [participants, travel, program];

  /// Deutsche Bezeichnung einer Phase.
  static String label(String topic) => switch (topic) {
    participants => 'Wann und wer?',
    travel => 'Wo und wie?',
    program => 'Was machen wir?',
    _ => topic,
  };
}

/// Übersetzt Integer-Flags der API (`1`) und echte Bools in `bool`.
bool _asBool(Object? value) => value == true || value == 1;

/// Kurzinfo einer Planungsreise (`TravelPlanningTrip`).
class PlanningTrip {
  final String id;
  final String name;
  final String? description;
  final String state;
  final bool allDay;
  final String timezone;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? startDate;
  final DateTime? endDate;

  /// Rolle des aktuellen Nutzers in der Planung (`leader`/`member`).
  final String? role;

  /// Eigener Mitgliedsstatus (`invited`/`accepted`/`declined`/`inactive`).
  final String? memberStatus;

  /// Ob der aktuelle Nutzer die Leitung ist (vom Server gesetzt).
  final bool canManage;
  final int memberCount;

  /// Status je Phase: `pending`/`in_progress`/`completed`/`skipped`.
  final Map<String, String> topicStatus;
  final String? conversationId;

  const PlanningTrip({
    required this.id,
    required this.name,
    this.description,
    required this.state,
    this.allDay = true,
    this.timezone = 'UTC',
    this.startAt,
    this.endAt,
    this.startDate,
    this.endDate,
    this.role,
    this.memberStatus,
    this.canManage = false,
    this.memberCount = 0,
    this.topicStatus = const {},
    this.conversationId,
  });

  /// Ob bereits ein verbindlicher oder vorgeschlagener Termin gesetzt ist.
  bool get hasDate =>
      startAt != null || endAt != null || startDate != null || endDate != null;

  /// Status der Phase [topic]; `pending`, wenn unbekannt.
  String topicStatusFor(String topic) => topicStatus[topic] ?? 'pending';

  bool get isLeader => role == 'leader';

  factory PlanningTrip.fromJson(Map<String, dynamic> json) {
    return PlanningTrip(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      state: json['state'] as String? ?? 'planning',
      allDay: _asBool(json['allDay']),
      timezone: json['timezone'] as String? ?? 'UTC',
      startAt: _parseInstant(json['startAt']),
      endAt: _parseInstant(json['endAt']),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      role: json['role'] as String?,
      memberStatus: json['memberStatus'] as String?,
      canManage: _asBool(json['canManage']),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      topicStatus: _parseTopicStatus(json['topicStatus']),
      conversationId: json['conversationId'] as String?,
    );
  }

  static Map<String, String> _parseTopicStatus(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.value is String) entry.key.toString(): entry.value as String,
    };
  }
}

/// Vollständige Planungsdetails (`TravelPlanningTripDetail`).
class PlanningTripDetail extends PlanningTrip {
  final List<PlanTopic> topics;
  final List<PlanMember> members;
  final List<PlanDateOption> dateOptions;
  final List<PlanTransport> transport;
  final List<PlanAccommodationOption> accommodationOptions;
  final List<PlanEventSuggestion> eventSuggestions;

  const PlanningTripDetail({
    required super.id,
    required super.name,
    super.description,
    required super.state,
    super.allDay,
    super.timezone,
    super.startAt,
    super.endAt,
    super.startDate,
    super.endDate,
    super.role,
    super.memberStatus,
    super.canManage,
    super.memberCount,
    super.topicStatus,
    super.conversationId,
    this.topics = const [],
    this.members = const [],
    this.dateOptions = const [],
    this.transport = const [],
    this.accommodationOptions = const [],
    this.eventSuggestions = const [],
  });

  factory PlanningTripDetail.fromJson(Map<String, dynamic> json) {
    final base = PlanningTrip.fromJson(json);
    return PlanningTripDetail(
      id: base.id,
      name: base.name,
      description: base.description,
      state: base.state,
      allDay: base.allDay,
      timezone: base.timezone,
      startAt: base.startAt,
      endAt: base.endAt,
      startDate: base.startDate,
      endDate: base.endDate,
      role: base.role,
      memberStatus: base.memberStatus,
      canManage: base.canManage,
      memberCount: base.memberCount,
      topicStatus: base.topicStatus,
      conversationId: base.conversationId,
      topics: _list(json['topics'], PlanTopic.fromJson),
      members: _list(json['members'], PlanMember.fromJson),
      dateOptions: _list(json['dateOptions'], PlanDateOption.fromJson),
      transport: _list(json['transport'], PlanTransport.fromJson),
      accommodationOptions: _list(
        json['accommodationOptions'],
        PlanAccommodationOption.fromJson,
      ),
      eventSuggestions: _list(
        json['eventSuggestions'],
        PlanEventSuggestion.fromJson,
      ),
    );
  }
}

/// Phasenstatus (`TravelPlanTopic`).
class PlanTopic {
  final String id;
  final String tripId;
  final String topic;
  final String status;

  const PlanTopic({
    required this.id,
    required this.tripId,
    required this.topic,
    required this.status,
  });

  factory PlanTopic.fromJson(Map<String, dynamic> json) {
    return PlanTopic(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      topic: json['topic'] as String,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

/// Planungsteilnehmer (`TravelPlanMember`).
class PlanMember {
  final String memberId;
  final String tripId;
  final String userId;
  final String status;
  final String role;
  final String? origin;
  final String? email;
  final String? displayName;
  final String? image;

  const PlanMember({
    required this.memberId,
    required this.tripId,
    required this.userId,
    required this.status,
    required this.role,
    this.origin,
    this.email,
    this.displayName,
    this.image,
  });

  bool get isLeader => role == 'leader';
  bool get isInactive => status == 'inactive';

  factory PlanMember.fromJson(Map<String, dynamic> json) {
    return PlanMember(
      memberId: json['memberId'] as String,
      tripId: json['tripId'] as String,
      userId: json['userId'] as String,
      status: json['status'] as String? ?? 'invited',
      role: json['role'] as String? ?? 'member',
      origin: json['origin'] as String?,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      image: json['image'] as String?,
    );
  }
}

/// Verfügbarkeits-Rückmeldung (`TravelPlanDateResponse`).
class PlanDateResponse {
  final String userId;
  final String availability;

  const PlanDateResponse({required this.userId, required this.availability});

  factory PlanDateResponse.fromJson(Map<String, dynamic> json) {
    return PlanDateResponse(
      userId: json['userId'] as String,
      availability: json['availability'] as String,
    );
  }
}

/// Terminoption (`TravelPlanDateOption`), zeitzonen-bewusst.
class PlanDateOption {
  final String id;
  final String tripId;
  final String? label;
  final bool allDay;
  final String timezone;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isFinal;
  final String? proposedBy;
  final int position;
  final List<PlanDateResponse> responses;

  const PlanDateOption({
    required this.id,
    required this.tripId,
    this.label,
    this.allDay = true,
    this.timezone = 'UTC',
    this.startAt,
    this.endAt,
    this.startDate,
    this.endDate,
    this.isFinal = false,
    this.proposedBy,
    this.position = 0,
    this.responses = const [],
  });

  factory PlanDateOption.fromJson(Map<String, dynamic> json) {
    return PlanDateOption(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      label: json['label'] as String?,
      allDay: _asBool(json['allDay']),
      timezone: json['timezone'] as String? ?? 'UTC',
      startAt: _parseInstant(json['startAt']),
      endAt: _parseInstant(json['endAt']),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      isFinal: _asBool(json['isFinal']),
      proposedBy: json['proposedBy'] as String?,
      position: (json['position'] as num?)?.toInt() ?? 0,
      responses: _list(json['responses'], PlanDateResponse.fromJson),
    );
  }
}

/// Transportpräferenz je Mitglied/Richtung (`TravelPlanTransport`).
class PlanTransport {
  final String id;
  final String tripId;
  final String userId;
  final String direction;
  final String? mode;
  final bool offersRide;
  final int? availableSeats;
  final String? notes;
  final String? displayName;
  final String? image;

  const PlanTransport({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.direction,
    this.mode,
    this.offersRide = false,
    this.availableSeats,
    this.notes,
    this.displayName,
    this.image,
  });

  factory PlanTransport.fromJson(Map<String, dynamic> json) {
    return PlanTransport(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      userId: json['userId'] as String,
      direction: json['direction'] as String? ?? 'outbound',
      mode: json['mode'] as String?,
      offersRide: _asBool(json['offersRide']),
      availableSeats: (json['availableSeats'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      displayName: json['displayName'] as String?,
      image: json['image'] as String?,
    );
  }
}

/// Unterkunftsoption inkl. Preis pro Person und Nacht
/// (`TravelPlanAccommodationOption`).
class PlanAccommodationOption {
  final String id;
  final String tripId;
  final String? accommodationId;
  final String? name;
  final String? description;
  final String? address;
  final int? osmId;
  final double? latitude;
  final double? longitude;
  final String? citySlug;

  /// Dezimalwert als String, z. B. `'42.50'`.
  final String? pricePerPersonPerNight;
  final String? currency;
  final bool isSelected;
  final String? proposedBy;

  const PlanAccommodationOption({
    required this.id,
    required this.tripId,
    this.accommodationId,
    this.name,
    this.description,
    this.address,
    this.osmId,
    this.latitude,
    this.longitude,
    this.citySlug,
    this.pricePerPersonPerNight,
    this.currency,
    this.isSelected = false,
    this.proposedBy,
  });

  factory PlanAccommodationOption.fromJson(Map<String, dynamic> json) {
    return PlanAccommodationOption(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      accommodationId: json['accommodationId'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      osmId: (json['OSMID'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      citySlug: json['citySlug'] as String?,
      pricePerPersonPerNight: json['pricePerPersonPerNight'] as String?,
      currency: json['currency'] as String?,
      isSelected: _asBool(json['isSelected']),
      proposedBy: json['proposedBy'] as String?,
    );
  }
}

/// Teilnahmeinteresse an einem Tagesprogramm-Vorschlag
/// (`TravelPlanEventInterest`).
class PlanEventInterest {
  final String userId;
  final String interest;

  const PlanEventInterest({required this.userId, required this.interest});

  factory PlanEventInterest.fromJson(Map<String, dynamic> json) {
    return PlanEventInterest(
      userId: json['userId'] as String,
      interest: json['interest'] as String,
    );
  }
}

/// Tagesprogramm-Vorschlag (`TravelPlanEventSuggestion`).
class PlanEventSuggestion {
  final String id;
  final String tripId;
  final String name;
  final String? description;
  final int dayIndex;
  final bool allDay;
  final String timezone;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? osmId;
  final String? citySlug;
  final bool isConfirmed;

  /// Nach Aktivierung erzeugtes `TravelEvent`.
  final String? confirmedEventId;
  final String? proposedBy;
  final List<PlanEventInterest> interests;

  const PlanEventSuggestion({
    required this.id,
    required this.tripId,
    required this.name,
    this.description,
    this.dayIndex = 0,
    this.allDay = false,
    this.timezone = 'UTC',
    this.startAt,
    this.endAt,
    this.startDate,
    this.endDate,
    this.address,
    this.latitude,
    this.longitude,
    this.osmId,
    this.citySlug,
    this.isConfirmed = false,
    this.confirmedEventId,
    this.proposedBy,
    this.interests = const [],
  });

  factory PlanEventSuggestion.fromJson(Map<String, dynamic> json) {
    return PlanEventSuggestion(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      dayIndex: (json['dayIndex'] as num?)?.toInt() ?? 0,
      allDay: _asBool(json['allDay']),
      timezone: json['timezone'] as String? ?? 'UTC',
      startAt: _parseInstant(json['startAt']),
      endAt: _parseInstant(json['endAt']),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      osmId: (json['OSMID'] as num?)?.toInt(),
      citySlug: json['citySlug'] as String?,
      isConfirmed: _asBool(json['isConfirmed']),
      confirmedEventId: json['confirmedEventId'] as String?,
      proposedBy: json['proposedBy'] as String?,
      interests: _list(json['interests'], PlanEventInterest.fromJson),
    );
  }
}

/// Paginierte Liste eigener Planungsreisen.
class PlanningTripListResponse {
  final List<PlanningTrip> data;

  const PlanningTripListResponse({required this.data});

  factory PlanningTripListResponse.fromJson(Map<String, dynamic> json) {
    return PlanningTripListResponse(
      data: _list(json['data'], PlanningTrip.fromJson),
    );
  }
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList(growable: false);
}

DateTime? _parseInstant(Object? raw) {
  final value = raw as String?;
  if (value == null || value.isEmpty) return null;
  return parseApiInstant(value);
}

DateTime? _parseDate(Object? raw) {
  final value = raw as String?;
  if (value == null || value.isEmpty) return null;
  return parseApiDateOnly(value);
}
