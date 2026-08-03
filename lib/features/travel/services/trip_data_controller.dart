import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../../subscription/models/subscription_models.dart';
import '../models/travel_models.dart';
import 'travel_service.dart';

/// Memoizes the section futures of the trip detail screen.
///
/// Each API slice of the screen (events, accommodations, participants,
/// tickets, subscriptions) is fetched once and shared by every widget that
/// needs it – events feed the Events tab, the map and the ticket event names.
/// Sections load and fail independently: one failing slice only surfaces in
/// its own section widget. Call [refresh] to discard all memoized futures;
/// the next access then refetches.
class TripDataController extends ChangeNotifier {
  TripDataController({
    required this.service,
    required this.tripId,
    this.currentUserId,
  });

  final TravelService service;
  final String tripId;

  /// Used to fetch tickets of events the current user participates in.
  final String? currentUserId;

  static final _log = Logger('trip_data');

  Future<List<TravelEvent>>? _events;
  Future<List<TravelAccommodation>>? _accommodations;
  Future<List<TravelParticipant>>? _participants;
  Future<List<Subscription>>? _subscriptions;
  Future<({List<TravelEventTicket> tickets, List<TravelEvent> events})>?
  _ticketSection;
  Future<
    ({List<TravelAccommodation> accommodations, List<TravelEvent> events})
  >?
  _mapSection;

  /// All events of the trip (Events tab, map, ticket event names).
  Future<List<TravelEvent>> get events => _events ??= _fetchEvents();

  /// Accommodations of the trip (overview, map).
  Future<List<TravelAccommodation>> get accommodations =>
      _accommodations ??= _fetchAccommodations();

  /// Participants of the trip (overview).
  Future<List<TravelParticipant>> get participants =>
      _participants ??= _fetchParticipants();

  /// Subscriptions of the trip (payments tab).
  Future<List<Subscription>> get subscriptions =>
      _subscriptions ??= _fetchSubscriptions();

  /// Trip and own event tickets, plus the events for name resolution.
  ///
  /// The event parts degrade gracefully: if the events request fails, the
  /// trip tickets still render and event names fall back to ids.
  Future<({List<TravelEventTicket> tickets, List<TravelEvent> events})>
  get ticketSection => _ticketSection ??= _fetchTicketSection();

  /// Accommodations and events for the map tab (shared, single fetch each).
  Future<({List<TravelAccommodation> accommodations, List<TravelEvent> events})>
  get mapSection => _mapSection ??= _fetchMapSection();

  /// Discards all memoized futures; the next access refetches.
  void refresh() {
    _events = null;
    _accommodations = null;
    _participants = null;
    _subscriptions = null;
    _ticketSection = null;
    _mapSection = null;
    notifyListeners();
  }

  Future<List<TravelEvent>> _fetchEvents() async {
    final response = await service.getEvents(tripId);
    return response.data;
  }

  Future<List<TravelAccommodation>> _fetchAccommodations() async {
    final response = await service.getAccommodations(tripId);
    return response.data;
  }

  Future<List<TravelParticipant>> _fetchParticipants() async {
    final response = await service.getParticipants(tripId);
    return response.data;
  }

  Future<List<Subscription>> _fetchSubscriptions() async {
    return service.getTripSubscriptions(tripId);
  }

  Future<({List<TravelEventTicket> tickets, List<TravelEvent> events})>
  _fetchTicketSection() async {
    final tripTickets = await service.getTripTickets(tripId);
    List<TravelEvent> eventList = const [];
    try {
      eventList = await events;
    } on Exception catch (e, st) {
      _log.warning(
        'Events unavailable; ticket event names fall back to ids',
        e,
        st,
      );
    }
    if (currentUserId == null) {
      return (tickets: tripTickets, events: eventList);
    }
    final myEventIds = eventList
        .where((e) => e.participants.any((p) => p.id == currentUserId))
        .map((e) => e.id)
        .toList();
    final lists = await Future.wait(
      myEventIds.map((id) async {
        try {
          return await service.getEventTickets(id);
        } on Exception catch (e, st) {
          _log.warning('Event tickets failed for $id', e, st);
          return <TravelEventTicket>[];
        }
      }),
    );
    return (
      tickets: [...tripTickets, ...lists.expand((l) => l)],
      events: eventList,
    );
  }

  Future<({List<TravelAccommodation> accommodations, List<TravelEvent> events})>
  _fetchMapSection() async {
    final (accommodations, events) = await (
      this.accommodations,
      this.events,
    ).wait;
    return (accommodations: accommodations, events: events);
  }
}
