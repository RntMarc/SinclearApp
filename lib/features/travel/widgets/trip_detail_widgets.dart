import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../../core/utils/url_helper.dart';
import '../../../core/widgets/async_section.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_map_card.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../subscription/models/subscription_models.dart';
import '../../subscription/screens/subscription_detail_screen.dart';
import '../../subscription/widgets/subscription_card.dart';
import '../models/travel_models.dart';
import '../screens/accommodation_detail_screen.dart';
import '../screens/event_detail_screen.dart';
import '../services/trip_data_controller.dart';
import '../widgets/ticket_preview_page.dart';
import '../widgets/user_tile.dart';

/// Overview tab: loads accommodations and participants independently, so a
/// failure in one only replaces that part with an inline error.
class TripOverviewSection extends StatelessWidget {
  final TravelTrip trip;
  final TripDataController controller;
  final String? currentUserId;
  final VoidCallback? onSelectMapTab;

  const TripOverviewSection({
    super.key,
    required this.trip,
    required this.controller,
    this.currentUserId,
    this.onSelectMapTab,
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
          if (trip.description != null) ...[
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
          AsyncSection<List<TravelAccommodation>>(
            future: controller.accommodations,
            keepAlive: true,
            skeleton: const _AccommodationsSkeleton(),
            builder: (context, accommodations) {
              if (accommodations.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TripAccommodationMap(
                    accommodations: accommodations,
                    currentUserId: currentUserId,
                    onTap: onSelectMapTab,
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
                      tripId: trip.id,
                    ),
                  ),
                ],
              );
            },
          ),
          AsyncSection<List<TravelParticipant>>(
            future: controller.participants,
            keepAlive: true,
            skeleton: const _ParticipantsSkeleton(),
            builder: (context, participants) {
              if (participants.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      child: UserTile(
                        displayName: p.displayName,
                        imageUrl: p.image,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class TripAccommodationMap extends StatelessWidget {
  final List<TravelAccommodation> accommodations;
  final String? currentUserId;
  final VoidCallback? onTap;

  const TripAccommodationMap({
    super.key,
    required this.accommodations,
    this.currentUserId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final coords = accommodations
        .where((a) => a.latitude != null && a.longitude != null)
        .toList();

    if (coords.isEmpty) {
      return const DesignMapCard(
        height: 200,
        emptyMessage: 'Keine Koordinaten verfügbar',
      );
    }

    final first = coords.first;
    final center = LatLng(first.latitude!, first.longitude!);

    final markers = coords.map((a) {
      final isMine =
          currentUserId != null && a.users.any((u) => u.id == currentUserId);
      return Marker(
        point: LatLng(a.latitude!, a.longitude!),
        child: Icon(
          Icons.location_on,
          color: isMine ? tokens.primary : tokens.danger,
          size: 36,
        ),
      );
    }).toList();

    return DesignMapCard(
      center: center,
      initialZoom: 13,
      markers: markers,
      height: 200,
      interactive: false,
      onTap: onTap,
    );
  }
}

class TripAccommodationCard extends StatelessWidget {
  final TravelAccommodation accommodation;
  final bool isMine;
  final String? tripId;

  const TripAccommodationCard({
    super.key,
    required this.accommodation,
    required this.isMine,
    this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      onTap: tripId != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccommodationDetailScreen(
                  tripId: tripId!,
                  accommodationId: accommodation.id,
                ),
              ),
            )
          : null,
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
              if (isMine) const DesignBadge(label: 'Meine Unterkunft'),
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TravelEventDetailScreen(id: event.id),
          ),
        ),
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
                Icon(Icons.event_rounded, color: tokens.primary, size: 20),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: DesignText(
                    event.name,
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                ),
                if (!participating) const DesignBadge(label: 'Nicht dabei'),
                if (event.hastickets == '1')
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.confirmation_number_rounded,
                      size: 16,
                      color: tokens.warning,
                    ),
                  ),
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

class TripTicketsTab extends StatelessWidget {
  final List<TravelEventTicket> tickets;
  final List<TravelEvent> events;
  final String? ticket;
  final String? ticketUrl;

  const TripTicketsTab({
    super.key,
    required this.tickets,
    required this.events,
    this.ticket,
    this.ticketUrl,
  });

  String _eventName(String eventId) {
    final idx = events.indexWhere((e) => e.id == eventId);
    return idx >= 0 ? events[idx].name : eventId;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    final hasTicketInfo =
        (ticket != null && ticket!.isNotEmpty) ||
        (ticketUrl != null && ticketUrl!.isNotEmpty);

    if (tickets.isEmpty && !hasTicketInfo) {
      return Center(
        child: DesignText(
          'Keine Tickets verfügbar',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }

    final tripTickets = tickets.where((t) => t.type == 'trip').toList();
    final eventTickets = tickets.where((t) => t.type == 'event').toList();
    final userTickets = tickets.where((t) => t.type == 'user').toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tripTickets.isNotEmpty) ...[
            DesignText(
              'Reise-Tickets',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceSm),
            ...tripTickets.map(
              (t) => _ticketCard(context, tokens, t, 'Reise-Ticket'),
            ),
            SizedBox(height: tokens.spaceLg),
          ],
          if (eventTickets.isNotEmpty) ...[
            DesignText(
              'Event-Tickets',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceSm),
            ...eventTickets.map(
              (t) => _ticketCard(
                context,
                tokens,
                t,
                'Event: ${_eventName(t.event ?? '')}',
              ),
            ),
            SizedBox(height: tokens.spaceLg),
          ],
          if (hasTicketInfo) ...[
            _ticketInfoCard(tokens, ticket, ticketUrl),
            SizedBox(height: tokens.spaceLg),
          ],
          if (userTickets.isNotEmpty) ...[
            DesignText(
              'Meine Tickets',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceSm),
            ...userTickets.map(
              (t) => _ticketCard(context, tokens, t, 'Mein Ticket'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ticketInfoCard(
    DesignTokens tokens,
    String? ticket,
    String? ticketUrl,
  ) {
    final hasUrl = ticketUrl != null && ticketUrl.isNotEmpty;
    return DesignCard(
      useGlass: false,
      onTap: hasUrl ? () => launchExternalUrl(ticketUrl) : null,
      margin: EdgeInsets.only(bottom: tokens.spaceSm),
      padding: EdgeInsets.all(tokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.confirmation_number_rounded,
                color: tokens.primary,
                size: 20,
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignText(
                  'Ticket-Info',
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                ),
              ),
              if (hasUrl)
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: tokens.primary,
                ),
            ],
          ),
          if (ticket != null && ticket.isNotEmpty) ...[
            SizedBox(height: tokens.spaceXs),
            DesignText(
              ticket,
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
          if (hasUrl) ...[
            SizedBox(height: tokens.spaceXs),
            DesignText(
              ticketUrl,
              style: DesignTextStyle.label,
              color: tokens.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _ticketCard(
    BuildContext context,
    DesignTokens tokens,
    TravelEventTicket t, [
    String label = 'Ticket',
  ]) {
    final hasQr = t.qrcode != null && t.qrcode!.isNotEmpty;
    final hasImg = t.image != null && resolveImageProvider(t.image) != null;

    return DesignCard(
      useGlass: false,
      margin: EdgeInsets.only(bottom: tokens.spaceSm),
      padding: EdgeInsets.all(tokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.confirmation_number_rounded,
                color: tokens.primary,
                size: 20,
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignText(
                  t.title ?? label,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                ),
              ),
            ],
          ),
          if (hasQr || hasImg) ...[
            SizedBox(height: tokens.spaceSm),
            SizedBox(
              height: 120,
              child: Row(
                children: [
                  if (hasQr)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketPreviewPage(
                              qrcode: t.qrcode,
                              title: t.title ?? label,
                            ),
                          ),
                        ),
                        child: QrImageView(
                          data: t.qrcode!,
                          size: 120,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (hasQr && hasImg) SizedBox(width: tokens.spaceSm),
                  if (hasImg)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketPreviewPage(
                              image: t.image,
                              title: t.title ?? label,
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(tokens.radiusSm),
                          child: Image(
                            image: resolveImageProvider(t.image)!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TripMapTab extends StatelessWidget {
  final List<TravelAccommodation> accommodations;
  final List<TravelEvent> events;
  final String? currentUserId;

  const TripMapTab({
    super.key,
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
          child: Icon(Icons.event_rounded, color: tokens.warning, size: 30),
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

    return DesignMapCard(
      center: first,
      initialZoom: 12,
      markers: markers,
      margin: EdgeInsets.all(tokens.spaceLg),
      interactive: true,
    );
  }
}

/// Events tab: loads the trip events on its own, so a failure only replaces
/// this tab with an inline error instead of breaking the whole screen.
class TripEventsSection extends StatelessWidget {
  final TripDataController controller;
  final String? currentUserId;

  const TripEventsSection({
    super.key,
    required this.controller,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncSection<List<TravelEvent>>(
      future: controller.events,
      keepAlive: true,
      skeleton: const _EventsSkeleton(),
      builder: (context, events) =>
          TripEventsTab(events: events, currentUserId: currentUserId),
    );
  }
}

/// Tickets tab: loads trip and own event tickets on its own.
class TripTicketsSection extends StatelessWidget {
  final TripDataController controller;
  final String? ticket;
  final String? ticketUrl;

  const TripTicketsSection({
    super.key,
    required this.controller,
    this.ticket,
    this.ticketUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncSection<
      ({List<TravelEventTicket> tickets, List<TravelEvent> events})
    >(
      future: controller.ticketSection,
      keepAlive: true,
      skeleton: const _TicketsSkeleton(),
      builder: (context, section) => TripTicketsTab(
        tickets: section.tickets,
        events: section.events,
        ticket: ticket,
        ticketUrl: ticketUrl,
      ),
    );
  }
}

/// Payments tab: loads the trip subscriptions on its own. A malformed
/// subscription only surfaces here, never in the rest of the screen.
class TripPaymentsSection extends StatelessWidget {
  final TripDataController controller;

  const TripPaymentsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AsyncSection<List<Subscription>>(
      future: controller.subscriptions,
      keepAlive: true,
      skeleton: const _PaymentsSkeleton(),
      builder: (context, subscriptions) {
        final tokens = DesignTheme.of(context);
        if (subscriptions.isEmpty) {
          return Center(
            child: DesignText(
              'Keine Zahlungen verfügbar',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            children: subscriptions.map((sub) {
              return Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceSm),
                child: SubscriptionCard(
                  subscription: sub,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SubscriptionDetailScreen(subscription: sub),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Map tab: loads accommodations and events (shared, single fetch each) on
/// its own.
class TripMapSection extends StatelessWidget {
  final TripDataController controller;
  final String? currentUserId;

  const TripMapSection({
    super.key,
    required this.controller,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncSection<
      ({List<TravelAccommodation> accommodations, List<TravelEvent> events})
    >(
      future: controller.mapSection,
      keepAlive: true,
      skeleton: const _MapSkeleton(),
      builder: (context, section) => TripMapTab(
        accommodations: section.accommodations,
        events: section.events,
        currentUserId: currentUserId,
      ),
    );
  }
}

/// Rounded placeholder bar used by the section skeletons.
class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({this.height = 14, this.widthFactor = 1});

  final double height;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: tokens.surfaceVariant.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
      ),
    );
  }
}

/// Mirrors the accommodation section (map, headline, one card) so the layout
/// does not jump when the data arrives.
class _AccommodationsSkeleton extends StatelessWidget {
  const _AccommodationsSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: tokens.surfaceVariant.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
        ),
        SizedBox(height: tokens.spaceLg),
        const _SkeletonBar(widthFactor: 0.4),
        SizedBox(height: tokens.spaceSm),
        const _SkeletonBar(),
        SizedBox(height: tokens.spaceSm),
        const _SkeletonBar(widthFactor: 0.8),
      ],
    );
  }
}

/// Mirrors the payments list (three grid cards) so the layout does not jump
/// when the data arrives.
class _PaymentsSkeleton extends StatelessWidget {
  const _PaymentsSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSm),
            child: const DesignCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SkeletonBar(widthFactor: 0.5),
                  SizedBox(height: 8),
                  _SkeletonBar(widthFactor: 0.8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mirrors the participant list (avatar + name rows) so the layout does not
/// jump when the data arrives.
class _ParticipantsSkeleton extends StatelessWidget {
  const _ParticipantsSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    Widget row() => Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: tokens.surfaceVariant.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        const Flexible(child: _SkeletonBar(widthFactor: 0.5)),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: tokens.spaceXl),
        const _SkeletonBar(widthFactor: 0.35),
        SizedBox(height: tokens.spaceSm),
        row(),
        SizedBox(height: tokens.spaceSm),
        row(),
      ],
    );
  }
}

/// Mirrors the event list (two event cards) so the layout does not jump when
/// the data arrives.
class _EventsSkeleton extends StatelessWidget {
  const _EventsSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    Widget card() => DesignCard(
      margin: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        0,
        tokens.spaceLg,
        tokens.spaceSm,
      ),
      padding: EdgeInsets.all(tokens.spaceMd),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _SkeletonCircle(size: 20),
              SizedBox(width: 8),
              Expanded(child: _SkeletonBar(widthFactor: 0.6)),
            ],
          ),
          SizedBox(height: 4),
          _SkeletonBar(widthFactor: 0.5),
          SizedBox(height: 4),
          _SkeletonBar(widthFactor: 0.35),
          SizedBox(height: 8),
          Row(
            children: [
              _SkeletonCircle(size: 24),
              SizedBox(width: 6),
              _SkeletonCircle(size: 24),
            ],
          ),
        ],
      ),
    );

    return Column(children: [card(), card()]);
  }
}

/// Mirrors the ticket cards (title row plus QR/image block) so the layout
/// does not jump when the data arrives.
class _TicketsSkeleton extends StatelessWidget {
  const _TicketsSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    Widget card() => DesignCard(
      useGlass: false,
      margin: EdgeInsets.only(bottom: tokens.spaceSm),
      padding: EdgeInsets.all(tokens.spaceMd),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _SkeletonCircle(size: 20),
              SizedBox(width: 8),
              Expanded(child: _SkeletonBar(widthFactor: 0.5)),
            ],
          ),
          SizedBox(height: 8),
          _SkeletonBar(height: 120),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(children: [card(), card()]),
    );
  }
}

/// Mirrors the map card (rounded box with screen-edge margin) so the layout
/// does not jump when the data arrives.
class _MapSkeleton extends StatelessWidget {
  const _MapSkeleton();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: tokens.surfaceVariant.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(tokens.radiusLg),
        ),
      ),
    );
  }
}

/// Round placeholder circle used by the section skeletons.
class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.surfaceVariant.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
    );
  }
}
