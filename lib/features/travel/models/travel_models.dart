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
