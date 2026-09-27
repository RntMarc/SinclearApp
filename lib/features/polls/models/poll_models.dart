import 'dart:convert';

import '../../../core/utils/date_utils.dart';

/// Art einer Umfrage. Der Diskriminator `type` bestimmt, welche Felder und
/// Endpunkte gelten.
enum PollType {
  form('form', 'Formular'),
  appointment('appointment', 'Terminfindung'),
  vote('vote', 'Abstimmung');

  const PollType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PollType fromApi(String? value) =>
      values.firstWhere((e) => e.apiValue == value, orElse: () => form);
}

/// Offen oder geschlossen.
enum PollStatus {
  open('open', 'Offen'),
  closed('closed', 'Geschlossen');

  const PollStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PollStatus fromApi(String? value) =>
      values.firstWhere((e) => e.apiValue == value, orElse: () => open);
}

/// Wer eine Umfrage sehen darf.
enum PollAccessMode {
  invited('invited', 'Nur Eingeladene'),
  allUsers('all_users', 'Alle Nutzer');

  const PollAccessMode(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PollAccessMode fromApi(String? value) =>
      values.firstWhere((e) => e.apiValue == value, orElse: () => invited);
}

/// Formular-Modus: einmal (änderbar) oder mehrfach.
enum PollSubmissionMode {
  single('single', 'Einmalig'),
  multiple('multiple', 'Mehrfach');

  const PollSubmissionMode(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PollSubmissionMode fromApi(String? value) =>
      values.firstWhere((e) => e.apiValue == value, orElse: () => single);
}

/// Sichtbarkeit der Formular-Ergebnisse.
enum PollResultsVisibility {
  creator('creator', 'Nur Ersteller'),
  participants('participants', 'Alle Teilnehmer');

  const PollResultsVisibility(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PollResultsVisibility fromApi(String? value) =>
      values.firstWhere((e) => e.apiValue == value, orElse: () => creator);
}

/// Die 13 Fragetypen der API (siehe `polls/types`).
enum PollQuestionType {
  text('text', 'Text'),
  textarea('textarea', 'Mehrzeiliger Text'),
  number('number', 'Zahl'),
  email('email', 'E-Mail'),
  coordinates('coordinates', 'Koordinaten'),
  date('date', 'Datum'),
  datetime('datetime', 'Datum & Uhrzeit'),
  url('url', 'URL'),
  phone('phone', 'Telefon'),
  singleChoice('single_choice', 'Einfachauswahl'),
  multipleChoice('multiple_choice', 'Mehrfachauswahl'),
  boolean('boolean', 'Ja/Nein'),
  rating('rating', 'Bewertung');

  const PollQuestionType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PollQuestionType fromApi(String? value) =>
      values.firstWhere((e) => e.apiValue == value, orElse: () => text);

  bool get hasOptions => this == singleChoice || this == multipleChoice;
}

/// Verfügbarkeit bei einer Terminfindung (Doodle-artig).
enum PollAvailability {
  yes('yes', 'Ja'),
  maybe('maybe', 'Vielleicht'),
  no('no', 'Nein');

  const PollAvailability(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static PollAvailability? fromApi(String? value) {
    for (final entry in values) {
      if (entry.apiValue == value) return entry;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Frage-Antwortwert-Semantik (siehe API-Doku `polls/types`)
// ---------------------------------------------------------------------------

/// Codiert einen booleschen Antwortwert als API-String `"1"`/`"0"`.
String encodeBooleanAnswer(bool value) => value ? '1' : '0';

/// Parst einen booleschen Antwortwert aus `"1"`/`"0"` bzw. `true`/`false`.
bool? parseBooleanAnswer(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  return switch (text) {
    '1' || 'true' || 'yes' || 'ja' => true,
    '0' || 'false' || 'no' || 'nein' => false,
    _ => null,
  };
}

/// Codiert Koordinaten als API-String `"lat,lon"`.
String encodeCoordinatesAnswer(double latitude, double longitude) =>
    '$latitude,$longitude';

/// Parst `"lat,lon"` zu einem `(latitude, longitude)`-Record.
({double latitude, double longitude})? parseCoordinatesAnswer(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  final parts = text.split(',');
  if (parts.length != 2) return null;
  final lat = double.tryParse(parts[0].trim());
  final lon = double.tryParse(parts[1].trim());
  if (lat == null || lon == null) return null;
  return (latitude: lat, longitude: lon);
}

/// Parst einen `multiple_choice`-Antwortwert (JSON-Array oder String) zu IDs.
List<String> parseMultipleChoiceAnswer(Object? value) {
  if (value == null) return const [];
  if (value is List) return value.map((e) => e.toString()).toList();
  final text = value.toString().trim();
  if (text.isEmpty) return const [];
  if (text.startsWith('[')) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } on FormatException {
      return const [];
    }
  }
  return [text];
}

// ---------------------------------------------------------------------------
// DTOs
// ---------------------------------------------------------------------------

/// Gemeinsamer Umfrage-Header (Kopf) aller drei Typen.
class Poll {
  final String id;
  final PollType type;
  final String creatorId;
  final String? creatorDisplayName;
  final String? creatorImage;
  final String title;
  final String? description;
  final PollStatus status;
  final DateTime? closesAt;
  final PollAccessMode accessMode;
  final PollSubmissionMode submissionMode;
  final PollResultsVisibility resultsVisibility;
  final bool allowCounterProposals;
  final bool allowMultiple;
  final String? finalizedOptionId;
  final bool isCreator;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Poll({
    required this.id,
    required this.type,
    required this.creatorId,
    this.creatorDisplayName,
    this.creatorImage,
    required this.title,
    this.description,
    required this.status,
    this.closesAt,
    required this.accessMode,
    required this.submissionMode,
    required this.resultsVisibility,
    required this.allowCounterProposals,
    this.allowMultiple = false,
    this.finalizedOptionId,
    required this.isCreator,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isClosed => status == PollStatus.closed;

  /// Ob die Frist abgelaufen ist (Status bleibt serverseitig bis zum Cron
  /// bzw. bis zum manuellen Schließen bestehen).
  bool get isPastDeadline {
    final closes = closesAt;
    return closes != null && closes.isBefore(DateTime.now().toUtc());
  }

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] as String,
      type: PollType.fromApi(json['type'] as String?),
      creatorId: json['creatorId'] as String,
      creatorDisplayName: json['creatorDisplayName'] as String?,
      creatorImage: json['creatorImage'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: PollStatus.fromApi(json['status'] as String?),
      closesAt: _parseInstantOrNull(json['closesAt']),
      accessMode: PollAccessMode.fromApi(json['accessMode'] as String?),
      submissionMode: PollSubmissionMode.fromApi(
        json['submissionMode'] as String?,
      ),
      resultsVisibility: PollResultsVisibility.fromApi(
        json['resultsVisibility'] as String?,
      ),
      allowCounterProposals: json['allowCounterProposals'] == true,
      allowMultiple: json['allowMultiple'] == true,
      finalizedOptionId: json['finalizedOptionId'] as String?,
      isCreator: json['isCreator'] == true,
      createdAt: parseApiInstant(json['createdAt'] as String),
      updatedAt: parseApiInstant(json['updatedAt'] as String),
    );
  }
}

/// Detail inklusive Fragen/Optionen und eigenem Teilnahmestatus.
class PollDetail {
  final Poll poll;
  final bool isInvited;
  final List<PollQuestion> questions;
  final List<PollOption> options;
  final PollParticipantStatus participantStatus;

  const PollDetail({
    required this.poll,
    required this.isInvited,
    required this.questions,
    required this.options,
    required this.participantStatus,
  });

  /// Optionen, die zu [questionId] gehören (Auswahl-Fragetypen).
  List<PollOption> optionsFor(String questionId) =>
      options.where((o) => o.questionId == questionId).toList();

  /// Terminvorschläge (ohne `questionId`).
  List<PollOption> get appointmentOptions =>
      options.where((o) => o.questionId == null).toList();

  factory PollDetail.fromJson(Map<String, dynamic> json) {
    return PollDetail(
      poll: Poll.fromJson(json),
      isInvited: json['isInvited'] == true,
      questions: ((json['questions'] as List?) ?? const [])
          .map((e) => PollQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      options: ((json['options'] as List?) ?? const [])
          .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      participantStatus: PollParticipantStatus.fromJson(
        (json['participantStatus'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

/// Eine Frage eines Formulars.
class PollQuestion {
  final String id;
  final String pollId;
  final PollQuestionType type;
  final String title;
  final String? description;
  final bool isRequired;
  final int position;
  final Map<String, dynamic> config;

  const PollQuestion({
    required this.id,
    required this.pollId,
    required this.type,
    required this.title,
    this.description,
    required this.isRequired,
    required this.position,
    this.config = const {},
  });

  int? intConfig(String key) {
    final value = config[key];
    return value is num ? value.toInt() : null;
  }

  double? doubleConfig(String key) {
    final value = config[key];
    return value is num ? value.toDouble() : null;
  }

  bool boolConfig(String key, {bool fallback = false}) {
    final value = config[key];
    return value is bool ? value : fallback;
  }

  String? stringConfig(String key) {
    final value = config[key];
    return value is String ? value : null;
  }

  List<String> labelsConfig() {
    final value = config['labels'];
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  factory PollQuestion.fromJson(Map<String, dynamic> json) {
    return PollQuestion(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      type: PollQuestionType.fromApi(json['type'] as String?),
      title: json['title'] as String,
      description: json['description'] as String?,
      isRequired: json['isRequired'] == true,
      position: (json['position'] as num?)?.toInt() ?? 0,
      config: (json['config'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Auswahloption, Terminvorschlag oder Gegenvorschlag.
class PollOption {
  final String id;
  final String pollId;
  final String? questionId;
  final String? label;
  final bool allDay;
  final String timezone;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCounterProposal;
  final String? proposedBy;
  final int position;

  const PollOption({
    required this.id,
    required this.pollId,
    this.questionId,
    this.label,
    required this.allDay,
    required this.timezone,
    this.startAt,
    this.endAt,
    this.startDate,
    this.endDate,
    required this.isCounterProposal,
    this.proposedBy,
    required this.position,
  });

  /// Anzeigelabel: für Terminvorschläge immer der formatierte Zeitraum in der
  /// Option-Zeitzone (eine freie Bezeichnung wird bewusst nicht angezeigt),
  /// sonst der gespeicherte [label] (Auswahl-/Abstimmungsoptionen).
  String get displayLabel {
    if (allDay) {
      final start = startDate;
      final end = endDate;
      if (start != null && end != null) return formatDayRange(start, end);
    } else {
      final start = startAt;
      final end = endAt;
      if (start != null && end != null) {
        return formatInstantRangeInZone(start, end, timezone);
      }
    }
    final own = label;
    if (own != null && own.isNotEmpty) return own;
    return allDay ? 'Ganztägig' : 'Termin';
  }

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      questionId: json['questionId'] as String?,
      label: json['label'] as String?,
      allDay: json['allDay'] == true,
      timezone: json['timezone'] as String? ?? 'UTC',
      startAt: _parseInstantOrNull(json['startAt']),
      endAt: _parseInstantOrNull(json['endAt']),
      startDate: _parseDateOnlyOrNull(json['startDate']),
      endDate: _parseDateOnlyOrNull(json['endDate']),
      isCounterProposal: json['isCounterProposal'] == true,
      proposedBy: json['proposedBy'] as String?,
      position: (json['position'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Einladung zu einer Umfrage.
class PollInvite {
  final String id;
  final String pollId;
  final String userId;
  final String? userDisplayName;
  final String? userImage;
  final bool isIndispensable;
  final DateTime createdAt;

  const PollInvite({
    required this.id,
    required this.pollId,
    required this.userId,
    this.userDisplayName,
    this.userImage,
    required this.isIndispensable,
    required this.createdAt,
  });

  factory PollInvite.fromJson(Map<String, dynamic> json) {
    return PollInvite(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String?,
      userImage: json['userImage'] as String?,
      isIndispensable: json['isIndispensable'] == true,
      createdAt: parseApiInstant(json['createdAt'] as String),
    );
  }
}

/// Eine Formular-Antwort inklusive der Werte je Frage.
class PollResponse {
  final String id;
  final String pollId;
  final String userId;
  final String? userDisplayName;
  final String? userImage;
  final Map<String, dynamic> answers;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PollResponse({
    required this.id,
    required this.pollId,
    required this.userId,
    this.userDisplayName,
    this.userImage,
    required this.answers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PollResponse.fromJson(Map<String, dynamic> json) {
    return PollResponse(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String?,
      userImage: json['userImage'] as String?,
      answers: (json['answers'] as Map<String, dynamic>?) ?? const {},
      createdAt: parseApiInstant(json['createdAt'] as String),
      updatedAt: parseApiInstant(json['updatedAt'] as String),
    );
  }
}

/// Verfügbarkeit eines Teilnehmers für einen Terminvorschlag.
class PollAvailabilityVote {
  final String id;
  final String optionId;
  final String userId;
  final String? userDisplayName;
  final String? userImage;
  final PollAvailability availability;
  final DateTime updatedAt;

  const PollAvailabilityVote({
    required this.id,
    required this.optionId,
    required this.userId,
    this.userDisplayName,
    this.userImage,
    required this.availability,
    required this.updatedAt,
  });

  factory PollAvailabilityVote.fromJson(Map<String, dynamic> json) {
    return PollAvailabilityVote(
      id: json['id'] as String,
      optionId: json['optionId'] as String,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String?,
      userImage: json['userImage'] as String?,
      availability:
          PollAvailability.fromApi(json['availability'] as String?) ??
          PollAvailability.maybe,
      updatedAt: parseApiInstant(json['updatedAt'] as String),
    );
  }
}

/// Ergebnis-Zählung einer Abstimmungsoption.
class PollResultEntry {
  final String optionId;
  final String? label;
  final int votes;
  final double percentage;

  const PollResultEntry({
    required this.optionId,
    this.label,
    required this.votes,
    required this.percentage,
  });

  factory PollResultEntry.fromJson(Map<String, dynamic> json) {
    return PollResultEntry(
      optionId: json['optionId'] as String,
      label: json['label'] as String?,
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Abstimmungsstatus des aktuellen Nutzers (anonyme Abstimmung).
class PollVoteStatus {
  final bool hasVoted;
  final List<String> votedOptionIds;

  const PollVoteStatus({
    required this.hasVoted,
    this.votedOptionIds = const [],
  });

  factory PollVoteStatus.fromJson(Map<String, dynamic> json) {
    return PollVoteStatus(
      hasVoted: json['hasVoted'] == true,
      votedOptionIds: ((json['votedOptionIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Eigener Teilnahmestatus einer Umfrage.
class PollParticipantStatus {
  final bool hasResponded;
  final bool hasAvailability;

  const PollParticipantStatus({
    this.hasResponded = false,
    this.hasAvailability = false,
  });

  factory PollParticipantStatus.fromJson(Map<String, dynamic> json) {
    return PollParticipantStatus(
      hasResponded: json['hasResponded'] == true,
      hasAvailability: json['hasAvailability'] == true,
    );
  }
}

// ---------------------------------------------------------------------------
// Antwort-/Request-Wrapper
// ---------------------------------------------------------------------------

class PollListResponse {
  final List<Poll> data;
  final PollPaginationMeta meta;

  const PollListResponse({required this.data, required this.meta});

  factory PollListResponse.fromJson(Map<String, dynamic> json) {
    return PollListResponse(
      data: ((json['data'] as List?) ?? const [])
          .map((e) => Poll.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: PollPaginationMeta.fromJson(
        (json['meta'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class PollPaginationMeta {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PollPaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory PollPaginationMeta.fromJson(Map<String, dynamic> json) {
    return PollPaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class PollInviteListResponse {
  final List<PollInvite> data;

  const PollInviteListResponse({required this.data});

  factory PollInviteListResponse.fromJson(Map<String, dynamic> json) {
    return PollInviteListResponse(
      data: ((json['data'] as List?) ?? const [])
          .map((e) => PollInvite.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PollResponseListResponse {
  final List<PollResponse> data;
  final int total;

  const PollResponseListResponse({required this.data, required this.total});

  factory PollResponseListResponse.fromJson(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};
    return PollResponseListResponse(
      data: ((json['data'] as List?) ?? const [])
          .map((e) => PollResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class PollAvailabilityListResponse {
  final List<PollAvailabilityVote> data;
  final int total;

  const PollAvailabilityListResponse({required this.data, required this.total});

  factory PollAvailabilityListResponse.fromJson(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};
    return PollAvailabilityListResponse(
      data: ((json['data'] as List?) ?? const [])
          .map((e) => PollAvailabilityVote.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (meta['total'] as num?)?.toInt() ?? 0,
    );
  }
}

class PollVoteResultResponse {
  final List<PollResultEntry> data;
  final int totalParticipants;

  const PollVoteResultResponse({
    required this.data,
    required this.totalParticipants,
  });

  factory PollVoteResultResponse.fromJson(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};
    return PollVoteResultResponse(
      data: ((json['data'] as List?) ?? const [])
          .map((e) => PollResultEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalParticipants: (meta['totalParticipants'] as num?)?.toInt() ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Requests
// ---------------------------------------------------------------------------

class PollQuestionInput {
  final PollQuestionType type;
  final String title;
  final String? description;
  final bool isRequired;
  final Map<String, dynamic>? config;
  final List<String> optionLabels;

  const PollQuestionInput({
    required this.type,
    required this.title,
    this.description,
    this.isRequired = false,
    this.config,
    this.optionLabels = const [],
  });

  Map<String, dynamic> toJson() => {
    'type': type.apiValue,
    'title': title,
    if (description != null && description!.isNotEmpty)
      'description': description,
    'isRequired': isRequired,
    if (config != null && config!.isNotEmpty) 'config': config,
    if (optionLabels.isNotEmpty)
      'options': optionLabels.map((label) => {'label': label}).toList(),
  };
}

class PollOptionInput {
  final String? label;
  final bool allDay;
  final String timezone;
  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? startDate;
  final DateTime? endDate;

  const PollOptionInput({
    this.label,
    this.allDay = false,
    this.timezone = 'Europe/Berlin',
    this.startAt,
    this.endAt,
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      if (label != null && label!.isNotEmpty) 'label': label,
      'allDay': allDay,
      'timezone': timezone,
    };
    if (allDay) {
      if (startDate != null) json['startDate'] = toApiDateOnly(startDate!);
      if (endDate != null) json['endDate'] = toApiDateOnly(endDate!);
    } else {
      if (startAt != null) json['startAt'] = toApiInstant(startAt!, timezone);
      if (endAt != null) json['endAt'] = toApiInstant(endAt!, timezone);
    }
    return json;
  }
}

class PollCreateRequest {
  final PollType type;
  final String title;
  final String? description;
  final DateTime? closesAt;
  final String closesAtTimezone;
  final PollAccessMode accessMode;
  final PollSubmissionMode submissionMode;
  final PollResultsVisibility resultsVisibility;
  final bool allowCounterProposals;
  final bool allowMultiple;
  final List<String> inviteUserIds;
  final List<PollQuestionInput> questions;
  final List<PollOptionInput> options;

  const PollCreateRequest({
    required this.type,
    required this.title,
    this.description,
    this.closesAt,
    this.closesAtTimezone = 'UTC',
    this.accessMode = PollAccessMode.invited,
    this.submissionMode = PollSubmissionMode.single,
    this.resultsVisibility = PollResultsVisibility.creator,
    this.allowCounterProposals = false,
    this.allowMultiple = false,
    this.inviteUserIds = const [],
    this.questions = const [],
    this.options = const [],
  });

  Map<String, dynamic> toJson() => {
    'type': type.apiValue,
    'title': title,
    if (description != null && description!.isNotEmpty)
      'description': description,
    if (closesAt != null) 'closesAt': toApiInstant(closesAt!, closesAtTimezone),
    'accessMode': accessMode.apiValue,
    if (type == PollType.form) 'submissionMode': submissionMode.apiValue,
    if (type == PollType.form) 'resultsVisibility': resultsVisibility.apiValue,
    if (type == PollType.appointment)
      'allowCounterProposals': allowCounterProposals,
    if (type == PollType.vote) 'allowMultiple': allowMultiple,
    if (inviteUserIds.isNotEmpty) 'inviteUserIds': inviteUserIds,
    if (questions.isNotEmpty)
      'questions': questions.map((q) => q.toJson()).toList(),
    if (options.isNotEmpty) 'options': options.map((o) => o.toJson()).toList(),
  };
}

class PollUpdateRequest {
  final String? title;
  final String? description;
  final DateTime? closesAt;
  final String closesAtTimezone;
  final PollAccessMode? accessMode;
  final PollStatus? status;
  final PollSubmissionMode? submissionMode;
  final PollResultsVisibility? resultsVisibility;
  final bool? allowCounterProposals;
  final bool? allowMultiple;

  const PollUpdateRequest({
    this.title,
    this.description,
    this.closesAt,
    this.closesAtTimezone = 'UTC',
    this.accessMode,
    this.status,
    this.submissionMode,
    this.resultsVisibility,
    this.allowCounterProposals,
    this.allowMultiple,
  });

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (closesAt != null) 'closesAt': toApiInstant(closesAt!, closesAtTimezone),
    if (accessMode != null) 'accessMode': accessMode!.apiValue,
    if (status != null) 'status': status!.apiValue,
    if (submissionMode != null) 'submissionMode': submissionMode!.apiValue,
    if (resultsVisibility != null)
      'resultsVisibility': resultsVisibility!.apiValue,
    if (allowCounterProposals != null)
      'allowCounterProposals': allowCounterProposals,
    if (allowMultiple != null) 'allowMultiple': allowMultiple,
  };
}

class PollAnswerInput {
  final String questionId;
  final Object? value;

  const PollAnswerInput({required this.questionId, this.value});

  Map<String, dynamic> toJson() => {'questionId': questionId, 'value': value};
}

class PollResponseSubmitRequest {
  final List<PollAnswerInput> answers;

  const PollResponseSubmitRequest({required this.answers});

  Map<String, dynamic> toJson() => {
    'answers': answers.map((a) => a.toJson()).toList(),
  };
}

class PollAvailabilityInput {
  final String optionId;
  final PollAvailability availability;

  const PollAvailabilityInput({
    required this.optionId,
    required this.availability,
  });

  Map<String, dynamic> toJson() => {
    'optionId': optionId,
    'availability': availability.apiValue,
  };
}

class PollAvailabilitySetRequest {
  final List<PollAvailabilityInput> availability;

  const PollAvailabilitySetRequest({required this.availability});

  Map<String, dynamic> toJson() => {
    'availability': availability.map((a) => a.toJson()).toList(),
  };
}

class PollFinalizeRequest {
  final String optionId;

  const PollFinalizeRequest({required this.optionId});

  Map<String, dynamic> toJson() => {'optionId': optionId};
}

class PollVoteRequest {
  final List<String> optionIds;

  const PollVoteRequest({required this.optionIds});

  Map<String, dynamic> toJson() => {'optionIds': optionIds};
}

// ---------------------------------------------------------------------------
// Date/Time-Helfer
// ---------------------------------------------------------------------------

DateTime? _parseInstantOrNull(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return parseApiInstant(value);
}

DateTime? _parseDateOnlyOrNull(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return parseApiDateOnly(value);
}
