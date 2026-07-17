import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/config/osm_config.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/travel_models.dart';
import '../widgets/user_tile.dart';

class TripOverviewTab extends StatelessWidget {
  final TravelTrip trip;
  final List<TravelAccommodation> accommodations;
  final List<TravelParticipant> participants;
  final String? currentUserId;

  const TripOverviewTab({super.key,
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
    final tokens = DesignTheme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            trip.name,
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          if (trip.description != null) ...[
            SizedBox(height: tokens.spaceSm),
            DesignText(
              trip.description!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
          ],
          SizedBox(height: tokens.spaceSm),
          DesignText(
            '${_formatDate(trip.start)} \u2013 ${_formatDate(trip.end)}',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceLg),
          if (accommodations.isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: TripAccommodationMap(
                accommodations: accommodations,
                currentUserId: currentUserId,
              ),
            ),
            SizedBox(height: tokens.spaceLg),
            DesignText(
              'Unterkünfte',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceSm),
            ...accommodations.map(
              (a) => TripAccommodationCard(
                accommodation: a,
                isMine:
                    currentUserId != null &&
                    a.users.any((u) => u.id == currentUserId),
              ),
            ),
          ],
          if (participants.isNotEmpty) ...[
            SizedBox(height: tokens.spaceXl),
            DesignText(
              'Teilnehmer',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceSm),
            ...participants.map(
              (p) => Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceSm),
                child: UserTile(displayName: p.displayName, imageUrl: p.image),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TripAccommodationMap extends StatelessWidget {
  final List<TravelAccommodation> accommodations;
  final String? currentUserId;

  const TripAccommodationMap({super.key, required this.accommodations, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final coords = accommodations
        .where((a) => a.latitude != null && a.longitude != null)
        .toList();

    if (coords.isEmpty) {
      return DesignCard(
        useGlass: false,
        margin: EdgeInsets.zero,
        child: SizedBox(
          height: 200,
          child: Center(
            child: DesignText(
              'Keine Koordinaten verfügbar',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ),
        ),
      );
    }

    final first = coords.first;
    final center = LatLng(first.latitude!, first.longitude!);

    return DesignCard(
      useGlass: false,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: SizedBox(
          height: 200,
          child: GestureDetector(
            onTap: () => DefaultTabController.of(context).animateTo(2),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
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
                        Icons.location_on,
                        color: isMine ? tokens.primary : tokens.danger,
                        size: 36,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TripAccommodationCard extends StatelessWidget {
  final TravelAccommodation accommodation;
  final bool isMine;

  const TripAccommodationCard({super.key, required this.accommodation, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      margin: EdgeInsets.only(bottom: tokens.spaceSm),
      padding: EdgeInsets.all(tokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                accommodation.ishotel == 1
                    ? Icons.hotel_rounded
                    : Icons.home_rounded,
                color: isMine ? tokens.primary : tokens.textHigh,
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignText(
                  accommodation.name,
                  style: DesignTextStyle.body,
                  color: isMine ? tokens.primary : tokens.textHigh,
                ),
              ),
              if (isMine) DesignBadge(label: 'Meine Unterkunft'),
            ],
          ),
          if (accommodation.address != null) ...[
            SizedBox(height: tokens.spaceXs),
            DesignText(
              accommodation.address!,
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
          if (accommodation.users.isNotEmpty) ...[
            SizedBox(height: tokens.spaceSm),
            Wrap(
              spacing: tokens.spaceXs,
              runSpacing: tokens.spaceXs,
              children: accommodation.users.map((u) {
                return DesignAvatar(
                  imageUrl: u.image,
                  name: u.displayName,
                  size: 28,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class TripEventsTab extends StatelessWidget {
  final List<TravelEvent> events;
  final String? currentUserId;

  const TripEventsTab({super.key, required this.events, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    if (events.isEmpty) {
      return Center(
        child: DesignText(
          'Keine Events für diese Reise',
          style: DesignTextStyle.body,
          color: tokens.textLow,
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

    Widget section(String title, List<TravelEvent> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLg,
              tokens.spaceLg,
              tokens.spaceLg,
              tokens.spaceSm,
            ),
            child: DesignText(
              title,
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
          ),
          ...items.map(
            (e) => TripEventCard(event: e, currentUserId: currentUserId),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: tokens.spaceXl),
      child: Column(
        children: [
          if (current.isNotEmpty) section('Aktuelle Events', current),
          if (future.isNotEmpty) section('Kommende Events', future),
          if (past.isNotEmpty) section('Vergangene Events', past),
        ],
      ),
    );
  }
}

class TripEventCard extends StatelessWidget {
  final TravelEvent event;
  final String? currentUserId;

  const TripEventCard({super.key, required this.event, this.currentUserId});

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
    final tokens = DesignTheme.of(context);
    final participating = _isParticipating;

    return Opacity(
      opacity: participating ? 1.0 : 0.5,
      child: DesignCard(
        margin: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          0,
          tokens.spaceLg,
          tokens.spaceSm,
        ),
        padding: EdgeInsets.all(tokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  color: tokens.primary,
                  size: 20,
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: DesignText(
                    event.name,
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                ),
                if (!participating) DesignBadge(label: 'Nicht dabei'),
              ],
            ),
            SizedBox(height: tokens.spaceXs),
            DesignText(
              '${_formatDateTime(event.start)} \u2013 ${_formatDateTime(event.end)}',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
            if (event.address != null) ...[
              SizedBox(height: tokens.spaceXs),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: tokens.textLow,
                  ),
                  SizedBox(width: tokens.spaceXs),
                  Expanded(
                    child: DesignText(
                      event.address!,
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                    ),
                  ),
                ],
              ),
            ],
            if (event.participants.isNotEmpty) ...[
              SizedBox(height: tokens.spaceSm),
              Wrap(
                spacing: tokens.spaceXs,
                runSpacing: tokens.spaceXs,
                children: event.participants.map((p) {
                  return DesignAvatar(
                    imageUrl: p.image,
                    name: p.displayName,
                    size: 24,
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

class TripMapTab extends StatelessWidget {
  final List<TravelAccommodation> accommodations;
  final List<TravelEvent> events;
  final String? currentUserId;

  const TripMapTab({super.key,
    required this.accommodations,
    required this.events,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final markers = <Marker>[];

    for (final a in accommodations) {
      if (a.latitude == null || a.longitude == null) continue;
      final isMine =
          currentUserId != null && a.users.any((u) => u.id == currentUserId);
      markers.add(
        Marker(
          point: LatLng(a.latitude!, a.longitude!),
          child: Icon(
            Icons.hotel_rounded,
            color: isMine ? tokens.primary : tokens.success,
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
          child: Icon(
            Icons.event_rounded,
            color: tokens.warning,
            size: 30,
          ),
        ),
      );
    }

    if (markers.isEmpty) {
      return Center(
        child: DesignText(
          'Keine Orte mit Koordinaten verfügbar',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }

    final first = markers.first.point;

    return DesignCard(
      useGlass: false,
      margin: EdgeInsets.all(tokens.spaceLg),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: first,
            initialZoom: 12,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: OsmConfig.tileUrlTemplate,
              userAgentPackageName: OsmConfig.tileUserAgent,
              tileProvider: osmTileProvider(),
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}
