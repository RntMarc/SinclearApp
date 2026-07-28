import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/osm_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../widgets/ticket_form_sheet.dart';
import '../widgets/ticket_preview_page.dart';

class TravelEventDetailScreen extends StatefulWidget {
  final String id;

  const TravelEventDetailScreen({super.key, required this.id});

  @override
  State<TravelEventDetailScreen> createState() =>
      _TravelEventDetailScreenState();
}

class _TravelEventDetailScreenState extends State<TravelEventDetailScreen> {
  TravelService get _service => AppScope.of(context).travel;

  TravelEvent? _event;
  List<TravelEventTicket> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getEventUnified(widget.id),
        _service.getEventTickets(widget.id),
      ]);
      if (!mounted) return;
      setState(() {
        _event = results[0] as TravelEvent;
        _tickets = results[1] as List<TravelEventTicket>;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load event', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: _event?.name ?? 'Event',
          ),
          Expanded(child: _buildBodyWithFab()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final tokens = DesignTheme.of(context);
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DesignText(
                    'Fehler beim Laden des Events',
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                  SizedBox(height: tokens.spaceMd),
                  DesignButton(
                    variant: DesignButtonVariant.outlined,
                    label: 'Erneut versuchen',
                    onPressed: _load,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final event = _event!;
    final localStart = event.start.toLocal();
    final localEnd = event.end.toLocal();

    String fmt(DateTime dt) {
      final d =
          '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
      final t =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '$d $t';
    }

    final hasCoords = event.latitude != null && event.longitude != null;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description != null && event.description!.isNotEmpty) ...[
              DesignText(
                event.description!,
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
            ],
            SizedBox(height: tokens.spaceLg),
            _infoRow(tokens, Icons.schedule_rounded, fmt(localStart)),
            SizedBox(height: tokens.spaceXs),
            _infoRow(tokens, Icons.schedule_rounded, 'bis ${fmt(localEnd)}'),
            if (event.organizer != null) ...[
              SizedBox(height: tokens.spaceXs),
              _infoRow(tokens, Icons.person_rounded, event.organizer!),
            ],
            if (event.address != null) ...[
              SizedBox(height: tokens.spaceXs),
              _infoRow(tokens, Icons.location_on_rounded, event.address!),
            ],
            if (hasCoords) ...[
              SizedBox(height: tokens.spaceLg),
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                child: SizedBox(
                  height: 180,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(event.latitude!, event.longitude!),
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: OsmConfig.tileUrlTemplate,
                        userAgentPackageName: OsmConfig.tileUserAgent,
                        tileProvider: osmTileProvider(),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(event.latitude!, event.longitude!),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (event.hastickets == '1' || _tickets.isNotEmpty) ...[
              SizedBox(height: tokens.spaceXl),
              DesignText(
                'Tickets',
                style: DesignTextStyle.subtitle,
                color: tokens.textHigh,
              ),
              SizedBox(height: tokens.spaceSm),
              if (event.hastickets == '1') ...[
                _ticketInfoCard(tokens, event.ticket, event.ticketUrl),
              ],
              ..._tickets.map((t) => _ticketCard(tokens, t)),
            ],
            if (event.participants.isNotEmpty) ...[
              SizedBox(height: tokens.spaceXl),
              DesignText(
                'Teilnehmer (${event.participants.length})',
                style: DesignTextStyle.subtitle,
                color: tokens.textHigh,
              ),
              SizedBox(height: tokens.spaceSm),
              Wrap(
                spacing: tokens.spaceSm,
                runSpacing: tokens.spaceSm,
                children: event.participants.map((p) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DesignAvatar(
                        imageUrl: p.image,
                        name: p.displayName,
                        size: 32,
                      ),
                      SizedBox(width: tokens.spaceXs),
                      DesignText(
                        p.displayName,
                        style: DesignTextStyle.label,
                        color: tokens.textHigh,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ticketInfoCard(
    DesignTokens tokens,
    String? ticket,
    String? ticketUrl,
  ) {
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
              DesignText(
                'Ticket-Info',
                style: DesignTextStyle.body,
                color: tokens.textHigh,
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
          if (ticketUrl != null && ticketUrl.isNotEmpty) ...[
            SizedBox(height: tokens.spaceXs),
            GestureDetector(
              onTap: () => {/* TODO: open URL */},
              child: DesignText(
                ticketUrl,
                style: DesignTextStyle.label,
                color: tokens.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addTicket() async {
    final result = await showTicketFormSheet(
      context: context,
      service: _service,
      eventId: widget.id,
    );
    if (result == true && mounted) _load();
  }

  Widget _buildBodyWithFab() {
    if (_loading || _error != null || _event == null) return _buildBody();
    return Stack(
      children: [
        _buildBody(),
        if (_event!.hastickets == '1')
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'event_ticket_fab',
              onPressed: _addTicket,
              tooltip: 'Ticket hinzufügen',
              child: const Icon(Icons.qr_code_scanner_rounded),
            ),
          ),
      ],
    );
  }

  Widget _ticketCard(DesignTokens tokens, TravelEventTicket t) {
    final label = t.type == 'event'
        ? 'Event-Ticket'
        : t.type == 'user'
            ? 'Mein Ticket'
            : 'Ticket';
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
              Icon(Icons.confirmation_number_rounded, color: tokens.primary, size: 20),
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
                        child: QrImageView(data: t.qrcode!, size: 120),
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
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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

  Widget _infoRow(DesignTokens tokens, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: tokens.textLow),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: DesignText(
            text,
            style: DesignTextStyle.body,
            color: tokens.textHigh,
          ),
        ),
      ],
    );
  }
}
