import '../../../core/utils/date_utils.dart';
import 'travel_models.dart';

class PtStation {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;

  const PtStation({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
  });

  factory PtStation.fromJson(Map<String, dynamic> json) {
    return PtStation(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class PtStationListResponse {
  final List<PtStation> data;

  const PtStationListResponse({required this.data});

  factory PtStationListResponse.fromJson(Map<String, dynamic> json) {
    return PtStationListResponse(
      data: (json['data'] as List)
          .map((e) => PtStation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PtLeg {
  final String mode;
  final String? lineName;
  final String? lineProduct;
  final String? fromStationId;
  final String? fromStationName;
  final String? toStationId;
  final String? toStationName;
  final String? tripId;
  final DateTime? plannedDeparture;
  final DateTime? plannedArrival;
  final int? departureDelay;
  final int? arrivalDelay;
  final String? departurePlatform;
  final String? arrivalPlatform;
  final bool cancelled;
  final String? realTimeState;

  const PtLeg({
    required this.mode,
    this.lineName,
    this.lineProduct,
    this.fromStationId,
    this.fromStationName,
    this.toStationId,
    this.toStationName,
    this.tripId,
    this.plannedDeparture,
    this.plannedArrival,
    this.departureDelay,
    this.arrivalDelay,
    this.departurePlatform,
    this.arrivalPlatform,
    this.cancelled = false,
    this.realTimeState,
  });

  factory PtLeg.fromJson(Map<String, dynamic> json) {
    return PtLeg(
      mode: json['mode'] as String? ?? 'UNKNOWN',
      lineName: json['lineName'] as String?,
      lineProduct: json['lineProduct'] as String?,
      fromStationId: json['fromStationId'] as String?,
      fromStationName: json['fromStationName'] as String?,
      toStationId: json['toStationId'] as String?,
      toStationName: json['toStationName'] as String?,
      tripId: json['tripId'] as String?,
      plannedDeparture: json['plannedDeparture'] != null
          ? parseApiDate(json['plannedDeparture'] as String)
          : null,
      plannedArrival: json['plannedArrival'] != null
          ? parseApiDate(json['plannedArrival'] as String)
          : null,
      departureDelay: json['departureDelay'] as int?,
      arrivalDelay: json['arrivalDelay'] as int?,
      departurePlatform: json['departurePlatform'] as String?,
      arrivalPlatform: json['arrivalPlatform'] as String?,
      cancelled: json['cancelled'] as bool? ?? false,
      realTimeState: json['realTimeState'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      if (lineName != null) 'lineName': lineName,
      if (lineProduct != null) 'lineProduct': lineProduct,
      if (fromStationId != null) 'fromStationId': fromStationId,
      if (fromStationName != null) 'fromStationName': fromStationName,
      if (toStationId != null) 'toStationId': toStationId,
      if (toStationName != null) 'toStationName': toStationName,
      if (tripId != null) 'tripId': tripId,
      if (plannedDeparture != null)
        'plannedDeparture': toApiDate(plannedDeparture!),
      if (plannedArrival != null) 'plannedArrival': toApiDate(plannedArrival!),
      if (departureDelay != null) 'departureDelay': departureDelay,
      if (arrivalDelay != null) 'arrivalDelay': arrivalDelay,
      if (departurePlatform != null) 'departurePlatform': departurePlatform,
      if (arrivalPlatform != null) 'arrivalPlatform': arrivalPlatform,
      'cancelled': cancelled ? 1 : 0,
      if (realTimeState != null) 'realTimeState': realTimeState,
    };
  }
}

class PtJourneySearchResult {
  final int duration;
  final int transfers;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final List<PtLeg> legs;

  const PtJourneySearchResult({
    required this.duration,
    required this.transfers,
    this.departureTime,
    this.arrivalTime,
    this.legs = const [],
  });

  factory PtJourneySearchResult.fromJson(Map<String, dynamic> json) {
    return PtJourneySearchResult(
      duration: json['duration'] as int,
      transfers: json['transfers'] as int? ?? 0,
      departureTime: json['departureTime'] != null
          ? parseApiDate(json['departureTime'] as String)
          : null,
      arrivalTime: json['arrivalTime'] != null
          ? parseApiDate(json['arrivalTime'] as String)
          : null,
      legs:
          (json['legs'] as List?)
              ?.map((e) => PtLeg.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PtJourneySearchResponse {
  final List<PtJourneySearchResult> data;

  const PtJourneySearchResponse({required this.data});

  factory PtJourneySearchResponse.fromJson(Map<String, dynamic> json) {
    return PtJourneySearchResponse(
      data: (json['data'] as List)
          .map((e) => PtJourneySearchResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

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

class PtSavedJourney {
  final String id;
  final String? tripId;
  final String creatorId;
  final String fromStationId;
  final String fromStationName;
  final String toStationId;
  final String toStationName;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int duration;
  final int transfers;
  final DateTime chosenAt;
  final DateTime createdAt;
  final List<PtLeg> legs;
  final List<UserBrief> participants;

  const PtSavedJourney({
    required this.id,
    this.tripId,
    required this.creatorId,
    required this.fromStationId,
    required this.fromStationName,
    required this.toStationId,
    required this.toStationName,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.transfers,
    required this.chosenAt,
    required this.createdAt,
    this.legs = const [],
    this.participants = const [],
  });

  factory PtSavedJourney.fromJson(Map<String, dynamic> json) {
    return PtSavedJourney(
      id: json['id'] as String,
      tripId: json['tripId'] as String?,
      creatorId: json['creatorId'] as String,
      fromStationId: json['fromStationId'] as String,
      fromStationName: json['fromStationName'] as String,
      toStationId: json['toStationId'] as String,
      toStationName: json['toStationName'] as String,
      departureTime: parseApiDate(json['departureTime'] as String),
      arrivalTime: parseApiDate(json['arrivalTime'] as String),
      duration: json['duration'] as int,
      transfers: json['transfers'] as int? ?? 0,
      chosenAt: parseApiDate(json['chosenAt'] as String),
      createdAt: parseApiDate(json['createdAt'] as String),
      legs:
          (json['legs'] as List?)
              ?.map((e) => PtLeg.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      participants:
          (json['participants'] as List?)
              ?.map((e) => UserBrief.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PtSavedJourneyListResponse {
  final List<PtSavedJourney> data;
  final PaginationMeta meta;

  const PtSavedJourneyListResponse({required this.data, required this.meta});

  factory PtSavedJourneyListResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['data'] as List)
        .map((e) => PtSavedJourney.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] != null
        ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            page: 1,
            limit: items.length,
            total: items.length,
            totalPages: 1,
          );
    return PtSavedJourneyListResponse(data: items, meta: meta);
  }
}

class PtSaveJourneyRequest {
  String? tripId;
  String fromStationId;
  String fromStationName;
  String toStationId;
  String toStationName;
  String departureTime;
  String arrivalTime;
  int duration;
  int transfers;
  List<Map<String, dynamic>> legs;
  List<String> participantIds;

  PtSaveJourneyRequest({
    this.tripId,
    required this.fromStationId,
    required this.fromStationName,
    required this.toStationId,
    required this.toStationName,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.transfers,
    required this.legs,
    this.participantIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      if (tripId != null) 'tripId': tripId,
      'fromStationId': fromStationId,
      'fromStationName': fromStationName,
      'toStationId': toStationId,
      'toStationName': toStationName,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'duration': duration,
      'transfers': transfers,
      'legs': legs,
      if (participantIds.isNotEmpty) 'participantIds': participantIds,
    };
  }
}
