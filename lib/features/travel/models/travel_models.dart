class TravelTrip {
  final String id;
  final String name;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String hastickets;
  final String? ticket;
  final String? ticketUrl;

  const TravelTrip({
    required this.id,
    required this.name,
    this.description,
    required this.start,
    required this.end,
    required this.hastickets,
    this.ticket,
    this.ticketUrl,
  });

  factory TravelTrip.fromJson(Map<String, dynamic> json) {
    return TravelTrip(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      hastickets: json['hastickets'] as String,
      ticket: json['ticket'] as String?,
      ticketUrl: json['ticketUrl'] as String?,
    );
  }
}

class TravelEvent {
  final String id;
  final String? trip;
  final String name;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String hastickets;
  final String? ticket;
  final String? ticketUrl;
  final String? url;
  final String? image;
  final String? organizer;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? osmId;
  final List<TravelParticipantBrief> participants;

  const TravelEvent({
    required this.id,
    this.trip,
    required this.name,
    this.description,
    required this.start,
    required this.end,
    required this.hastickets,
    this.ticket,
    this.ticketUrl,
    this.url,
    this.image,
    this.organizer,
    this.address,
    this.latitude,
    this.longitude,
    this.osmId,
    this.participants = const [],
  });

  factory TravelEvent.fromJson(Map<String, dynamic> json) {
    return TravelEvent(
      id: json['ID'] as String,
      trip: json['trip'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      hastickets: json['hastickets'] as String,
      ticket: json['ticket'] as String?,
      ticketUrl: json['ticketUrl'] as String?,
      url: json['url'] as String?,
      image: json['image'] as String?,
      organizer: json['organizer'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      osmId: json['OSMID'] as int?,
      participants: (json['participants'] as List?)
              ?.map((e) => TravelParticipantBrief.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TravelAccommodation {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final int? osmId;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? mail;
  final int ishotel;
  final List<TravelParticipantBrief> users;

  const TravelAccommodation({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.osmId,
    this.latitude,
    this.longitude,
    this.phone,
    this.mail,
    required this.ishotel,
    this.users = const [],
  });

  factory TravelAccommodation.fromJson(Map<String, dynamic> json) {
    return TravelAccommodation(
      id: json['ID'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      osmId: json['OSMID'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      mail: json['mail'] as String?,
      ishotel: json['ishotel'] as int,
      users: (json['users'] as List?)
              ?.map((e) => TravelParticipantBrief.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TravelParticipantBrief {
  final String id;
  final String displayName;
  final String? image;

  const TravelParticipantBrief({
    required this.id,
    required this.displayName,
    this.image,
  });

  factory TravelParticipantBrief.fromJson(Map<String, dynamic> json) {
    return TravelParticipantBrief(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      image: json['image'] as String?,
    );
  }
}

class TravelParticipant {
  final String id;
  final String email;
  final String displayName;
  final String? image;

  const TravelParticipant({
    required this.id,
    required this.email,
    required this.displayName,
    this.image,
  });

  factory TravelParticipant.fromJson(Map<String, dynamic> json) {
    return TravelParticipant(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      image: json['image'] as String?,
    );
  }
}

class TimelineEntry {
  final String id;
  final String name;
  final String? description;
  final DateTime start;
  final DateTime end;
  final bool isTrip;

  const TimelineEntry({
    required this.id,
    required this.name,
    this.description,
    required this.start,
    required this.end,
    required this.isTrip,
  });
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

class TravelTripListResponse {
  final List<TravelTrip> data;
  final PaginationMeta meta;

  const TravelTripListResponse({required this.data, required this.meta});

  factory TravelTripListResponse.fromJson(Map<String, dynamic> json) {
    final trips = (json['data'] as List)
        .map((e) => TravelTrip.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] != null
        ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            page: 1,
            limit: trips.length,
            total: trips.length,
            totalPages: 1,
          );
    return TravelTripListResponse(data: trips, meta: meta);
  }
}

class TravelEventListResponse {
  final List<TravelEvent> data;

  const TravelEventListResponse({required this.data});

  factory TravelEventListResponse.fromJson(Map<String, dynamic> json) {
    return TravelEventListResponse(
      data: (json['data'] as List)
          .map((e) => TravelEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TravelStandaloneEventListResponse {
  final List<TravelEvent> data;
  final PaginationMeta meta;

  const TravelStandaloneEventListResponse({required this.data, required this.meta});

  factory TravelStandaloneEventListResponse.fromJson(Map<String, dynamic> json) {
    final events = (json['data'] as List)
        .map((e) => TravelEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] != null
        ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
        : PaginationMeta(
            page: 1,
            limit: events.length,
            total: events.length,
            totalPages: 1,
          );
    return TravelStandaloneEventListResponse(data: events, meta: meta);
  }
}

class TravelAccommodationListResponse {
  final List<TravelAccommodation> data;

  const TravelAccommodationListResponse({required this.data});

  factory TravelAccommodationListResponse.fromJson(Map<String, dynamic> json) {
    return TravelAccommodationListResponse(
      data: (json['data'] as List)
          .map((e) => TravelAccommodation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TravelParticipantListResponse {
  final List<TravelParticipant> data;

  const TravelParticipantListResponse({required this.data});

  factory TravelParticipantListResponse.fromJson(Map<String, dynamic> json) {
    return TravelParticipantListResponse(
      data: (json['data'] as List)
          .map((e) => TravelParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
