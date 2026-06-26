import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/osm_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../widgets/user_tile.dart';

class TripDetailScreen extends StatefulWidget {
  final String id;

  const TripDetailScreen({super.key, required this.id});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  TravelService get _service => AppScope.of(context).travel;

  bool _loading = true;
  String? _error;

  TravelTrip? _trip;
  List<TravelEvent> _events = [];
  List<TravelAccommodation> _accommodations = [];
  List<TravelParticipant> _participants = [];
  bool _hasLoaded = false;
  int _selectedTab = 0;

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
    } catch (e, st) {
      developer.log('Failed to load trip detail', error: e, stackTrace: st);
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
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Fehler beim Laden der Reisedetails'),
            const SizedBox(height: 8),
            CupertinoButton.filled(
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

    final tabLabels = {0: 'Übersicht', 1: 'Events', 2: 'Karte'};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: CupertinoSegmentedControl<int>(
            children: tabLabels.map((i, label) => MapEntry(
                  i,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(label, style: const TextStyle(fontSize: 13)),
                  ),
                )),
            onValueChanged: (value) => setState(() => _selectedTab = value),
            groupValue: _selectedTab,
          ),
        ),
        Expanded(
          child: _selectedTab == 0
              ? _OverviewTab(
                  trip: trip,
                  accommodations: _accommodations,
                  participants: _participants,
                  currentUserId: currentUserId,
                )
              : _selectedTab == 1
                  ? _EventsTab(events: _events, currentUserId: currentUserId)
                  : _MapTab(
                      accommodations: _accommodations,
                      events: _events,
                      currentUserId: currentUserId,
                    ),
        ),
      ],
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
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.name,
            style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
          ),
          if (trip.description != null) ...[
            const SizedBox(height: 8),
            Text(
              trip.description!,
              style: CupertinoTheme.of(context).textTheme.textStyle,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${_formatDate(trip.start)} – ${_formatDate(trip.end)}',
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(
              color: CupertinoColors.secondaryLabel,
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
              style: CupertinoTheme.of(
                context,
              ).textTheme.textStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            ...accommodations.map(
              (a) => _AccommodationCard(
                accommodation: a,
                isMine:
                    currentUserId != null &&
                    a.users.any((u) => u.id == currentUserId),
              ),
            ),
          ],
          if (participants.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Teilnehmer',
              style: CupertinoTheme.of(
                context,
              ).textTheme.textStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            ...participants.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: UserTile(displayName: p.displayName, imageUrl: p.image),
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

  const _AccommodationMap({required this.accommodations, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final coords = accommodations
        .where((a) => a.latitude != null && a.longitude != null)
        .toList();

    if (coords.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'Keine Koordinaten verfügbar',
              style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
        ),
      );
    }

    final first = coords.first;
    final center = LatLng(first.latitude!, first.longitude!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 13),
          children: [
            TileLayer(
              urlTemplate: OsmConfig.tileUrlTemplate,
              userAgentPackageName: OsmConfig.tileUserAgent,
              tileProvider: osmTileProvider(),
            ),
            MarkerLayer(
              markers: coords.map((a) {
                final isMine =
                    currentUserId != null &&
                    a.users.any((u) => u.id == currentUserId);
                return Marker(
                  point: LatLng(a.latitude!, a.longitude!),
                  child: Icon(
                    CupertinoIcons.location_solid,
                    color: isMine
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemRed,
                    size: 36,
                  ),
                );
              }).toList(),
            ),
            SimpleAttributionWidget(
              source: const Text('OpenStreetMap contributors'),
              onTap: () =>
                  launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
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

  const _AccommodationCard({required this.accommodation, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  accommodation.ishotel == 1
                      ? CupertinoIcons.book_fill
                      : CupertinoIcons.house_fill,
                  color: isMine
                      ? CupertinoColors.activeBlue
                      : theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    accommodation.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isMine
                          ? CupertinoColors.activeBlue
                          : null,
                    ),
                  ),
                ),
                if (isMine)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Meine Unterkunft',
                      style: TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                  ),
              ],
            ),
            if (accommodation.address != null) ...[
              const SizedBox(height: 4),
              Text(
                accommodation.address!,
                style: DefaultTextStyle.of(context).style.copyWith(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
            if (accommodation.users.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: accommodation.users.map((u) {
                  final provider = resolveImageProvider(u.image);
                  return ClipOval(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey3,
                        image: provider != null
                            ? DecorationImage(
                                image: provider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: provider == null
                          ? Center(
                              child: Text(
                                u.displayName.isNotEmpty
                                    ? u.displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
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

  const _EventsTab({required this.events, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          'Keine Events für diese Reise',
          style: CupertinoTheme.of(context).textTheme.textStyle,
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
          ...current.map(
            (e) => _EventCard(event: e, currentUserId: currentUserId),
          ),
        ],
        if (future.isNotEmpty) ...[
          _SectionHeader('Kommende Events'),
          ...future.map(
            (e) => _EventCard(event: e, currentUserId: currentUserId),
          ),
        ],
        if (past.isNotEmpty) ...[
          _SectionHeader('Vergangene Events'),
          ...past.map(
            (e) => _EventCard(event: e, currentUserId: currentUserId),
          ),
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
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 18,
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
    final local = dt.toLocal();
    final day =
        '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$day $time';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final participating = _isParticipating;

    return Opacity(
      opacity: participating ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    color: theme.primaryColor,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Nicht dabei',
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDateTime(event.start)} – ${_formatDateTime(event.end)}',
                style: DefaultTextStyle.of(context).style.copyWith(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              if (event.address != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.location_solid,
                      size: 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.address!,
                        style: DefaultTextStyle.of(context).style.copyWith(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel,
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
                    final provider = resolveImageProvider(p.image);
                    return ClipOval(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey3,
                          image: provider != null
                              ? DecorationImage(
                                  image: provider,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: provider == null
                            ? Center(
                                child: Text(
                                  p.displayName.isNotEmpty
                                      ? p.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              )
                            : null,
                      ),
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
      final isMine =
          currentUserId != null && a.users.any((u) => u.id == currentUserId);
      markers.add(
        Marker(
          point: LatLng(a.latitude!, a.longitude!),
          child: Icon(
            CupertinoIcons.book_fill,
            color: isMine
                ? CupertinoColors.activeBlue
                : CupertinoColors.activeGreen,
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
            CupertinoIcons.calendar,
            color: CupertinoColors.systemOrange,
            size: 30,
          ),
        ),
      );
    }

    if (markers.isEmpty) {
      return Center(
        child: Text(
          'Keine Orte mit Koordinaten verfügbar',
          style: CupertinoTheme.of(context).textTheme.textStyle,
        ),
      );
    }

    final first = markers.first.point;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.all(16),
        child: FlutterMap(
          options: MapOptions(initialCenter: first, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: OsmConfig.tileUrlTemplate,
              userAgentPackageName: OsmConfig.tileUserAgent,
              tileProvider: osmTileProvider(),
            ),
            MarkerLayer(markers: markers),
            SimpleAttributionWidget(
              source: const Text('OpenStreetMap contributors'),
              onTap: () =>
                  launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            ),
          ],
        ),
      ),
    );
  }
}
