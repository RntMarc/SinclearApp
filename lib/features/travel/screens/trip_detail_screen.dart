import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/di/app_scope.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../widgets/user_tile.dart';

class TripDetailScreen extends StatefulWidget {
  final String id;

  const TripDetailScreen({super.key, required this.id});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  TravelService get _service => AppScope.of(context).travel;

  bool _loading = true;
  String? _error;

  TravelTrip? _trip;
  List<TravelEvent> _events = [];
  List<TravelAccommodation> _accommodations = [];
  List<TravelParticipant> _participants = [];
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getTrip(widget.id),
        _service.getEvents(widget.id),
        _service.getAccommodations(widget.id),
        _service.getParticipants(widget.id),
      ]);

      if (!mounted) return;

      setState(() {
        _trip = results[0] as TravelTrip;
        _events = (results[1] as TravelEventListResponse).data;
        _accommodations = (results[2] as TravelAccommodationListResponse).data;
        _participants = (results[3] as TravelParticipantListResponse).data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Fehler beim Laden der Reisedetails'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    final trip = _trip;
    if (trip == null) {
      return const Center(child: Text('Reise nicht gefunden'));
    }

    final auth = AppScope.of(context).auth;
    final currentUserId = auth.userId;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Übersicht'),
              Tab(text: 'Events'),
              Tab(text: 'Karte'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OverviewTab(
                  trip: trip,
                  accommodations: _accommodations,
                  participants: _participants,
                  currentUserId: currentUserId,
                ),
                _EventsTab(
                  events: _events,
                  currentUserId: currentUserId,
                ),
                _MapTab(
                  accommodations: _accommodations,
                  events: _events,
                  currentUserId: currentUserId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final TravelTrip trip;
  final List<TravelAccommodation> accommodations;
  final List<TravelParticipant> participants;
  final String? currentUserId;

  const _OverviewTab({
    required this.trip,
    required this.accommodations,
    required this.participants,
    this.currentUserId,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trip.name, style: Theme.of(context).textTheme.headlineSmall),
          if (trip.description != null) ...[
            const SizedBox(height: 8),
            Text(
              trip.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${_formatDate(trip.start)} – ${_formatDate(trip.end)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          if (accommodations.isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: _AccommodationMap(
                accommodations: accommodations,
                currentUserId: currentUserId,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unterkünfte',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...accommodations.map(
              (a) => _AccommodationCard(
                accommodation: a,
                isMine: currentUserId != null &&
                    a.users.any((u) => u.id == currentUserId),
              ),
            ),
          ],
          if (participants.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Teilnehmer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...participants.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: UserTile(
                  displayName: p.displayName,
                  imageUrl: p.image,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccommodationMap extends StatelessWidget {
  final List<TravelAccommodation> accommodations;
  final String? currentUserId;

  const _AccommodationMap({
    required this.accommodations,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final coords = accommodations
        .where((a) => a.latitude != null && a.longitude != null)
        .toList();

    if (coords.isEmpty) {
      return Card(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'Keine Koordinaten verfügbar',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      );
    }

    final first = coords.first;
    final center = LatLng(first.latitude!, first.longitude!);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.sinclearapp',
            ),
            MarkerLayer(
              markers: coords.map((a) {
                final isMine = currentUserId != null &&
                    a.users.any((u) => u.id == currentUserId);
                return Marker(
                  point: LatLng(a.latitude!, a.longitude!),
                  child: Icon(
                    Icons.location_on,
                    color: isMine ? Colors.blue : Colors.red,
                    size: 36,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccommodationCard extends StatelessWidget {
  final TravelAccommodation accommodation;
  final bool isMine;

  const _AccommodationCard({
    required this.accommodation,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  accommodation.ishotel == 1
                      ? Icons.hotel_rounded
                      : Icons.home_rounded,
                  color: isMine ? Colors.blue : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    accommodation.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isMine ? Colors.blue : null,
                    ),
                  ),
                ),
                if (isMine)
                  Chip(
                    label: const Text('Meine Unterkunft',
                        style: TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            if (accommodation.address != null) ...[
              const SizedBox(height: 4),
              Text(
                accommodation.address!,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (accommodation.users.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: accommodation.users.map((u) {
                  return CircleAvatar(
                    radius: 14,
                    backgroundImage:
                        u.image != null ? NetworkImage(u.image!) : null,
                    child: u.image == null
                        ? Text(
                            u.displayName.isNotEmpty
                                ? u.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 11),
                          )
                        : null,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  final List<TravelEvent> events;
  final String? currentUserId;

  const _EventsTab({
    required this.events,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          'Keine Events für diese Reise',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final now = DateTime.now();
    final current = <TravelEvent>[];
    final future = <TravelEvent>[];
    final past = <TravelEvent>[];

    for (final e in events) {
      if (e.start.isBefore(now) && e.end.isAfter(now)) {
        current.add(e);
      } else if (e.start.isAfter(now)) {
        future.add(e);
      } else {
        past.add(e);
      }
    }

    current.sort((a, b) => a.start.compareTo(b.start));
    future.sort((a, b) => a.start.compareTo(b.start));
    past.sort((a, b) => b.end.compareTo(a.end));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (current.isNotEmpty) ...[
          _SectionHeader('Aktuelle Events'),
          ...current.map((e) => _EventCard(event: e, currentUserId: currentUserId)),
        ],
        if (future.isNotEmpty) ...[
          _SectionHeader('Kommende Events'),
          ...future.map((e) => _EventCard(event: e, currentUserId: currentUserId)),
        ],
        if (past.isNotEmpty) ...[
          _SectionHeader('Vergangene Events'),
          ...past.map((e) => _EventCard(event: e, currentUserId: currentUserId)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final TravelEvent event;
  final String? currentUserId;

  const _EventCard({required this.event, this.currentUserId});

  bool get _isParticipating =>
      currentUserId != null &&
      event.participants.any((p) => p.id == currentUserId);

  String _formatDateTime(DateTime dt) {
    final day =
        '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$day $time';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final participating = _isParticipating;

    return Opacity(
      opacity: participating ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!participating)
                    Chip(
                      label: const Text('Nicht dabei',
                          style: TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDateTime(event.start)} – ${_formatDateTime(event.end)}',
                style: theme.textTheme.bodySmall,
              ),
              if (event.address != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 16,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.address!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (event.participants.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: event.participants.map((p) {
                    return CircleAvatar(
                      radius: 12,
                      backgroundImage:
                          p.image != null ? NetworkImage(p.image!) : null,
                      child: p.image == null
                          ? Text(
                              p.displayName.isNotEmpty
                                  ? p.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 10),
                            )
                          : null,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  final List<TravelAccommodation> accommodations;
  final List<TravelEvent> events;
  final String? currentUserId;

  const _MapTab({
    required this.accommodations,
    required this.events,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    for (final a in accommodations) {
      if (a.latitude == null || a.longitude == null) continue;
      final isMine = currentUserId != null &&
          a.users.any((u) => u.id == currentUserId);
      markers.add(
        Marker(
          point: LatLng(a.latitude!, a.longitude!),
          child: Icon(
            Icons.hotel_rounded,
            color: isMine ? Colors.blue : Colors.green,
            size: 30,
          ),
        ),
      );
    }

    for (final e in events) {
      if (e.latitude == null || e.longitude == null) continue;
      markers.add(
        Marker(
          point: LatLng(e.latitude!, e.longitude!),
          child: const Icon(
            Icons.event_rounded,
            color: Colors.orange,
            size: 30,
          ),
        ),
      );
    }

    if (markers.isEmpty) {
      return Center(
        child: Text(
          'Keine Orte mit Koordinaten verfügbar',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final first = markers.first.point;

    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: first,
          initialZoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.sinclearapp',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
