import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../../core/utils/url_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_map_card.dart';
import '../../../design/widgets/composite/design_map_marker.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../core/widgets/open_in_map_button.dart';
import '../../../core/utils/map_helper.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../moderation/models/moderation_models.dart';
import '../../moderation/widgets/moderation_request_sheet.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../widgets/ticket_delete_flow.dart';
import '../widgets/ticket_form_sheet.dart';
import '../widgets/ticket_preview_page.dart';
import '../../chat/widgets/conversation_body.dart';
import '../../weather/widgets/weather_card.dart';

class TravelEventDetailScreen extends StatefulWidget {
  final String id;

  const TravelEventDetailScreen({super.key, required this.id});

  @override
  State<TravelEventDetailScreen> createState() =>
      _TravelEventDetailScreenState();
}

class _TravelEventDetailScreenState extends State<TravelEventDetailScreen>
    with TickerProviderStateMixin {
  TravelService get _service => AppScope.of(context).travel;

  TravelEvent? _event;
  List<TravelEventTicket> _tickets = [];
  bool _loading = true;
  String? _error;

  TabController? _tabController;
  int _currentTabIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _load();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _ensureTabController(int length) {
    if (_tabController != null && _tabController!.length == length) return;
    _tabController?.dispose();
    _tabController = TabController(length: length, vsync: this);
    _tabController!.addListener(() {
      if (!mounted) return;
      setState(() => _currentTabIndex = _tabController!.index);
    });
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
            actions: [
              if (_event != null)
                DesignIconButton(icon: Icons.flag_rounded, onPressed: _report),
            ],
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
            if (resolveImageProvider(event.image) != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                child: AspectRatio(
                  aspectRatio: 3.5 / 1,
                  child: Image(
                    image: resolveImageProvider(event.image)!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceLg),
            ],
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
            if (hasCoords) ...[
              SizedBox(height: tokens.spaceLg),
              Stack(
                children: [
                  DesignMapCard(
                    center: LatLng(event.latitude!, event.longitude!),
                    initialZoom: 14,
                    markers: [
                      designMapMarker(
                        point: LatLng(event.latitude!, event.longitude!),
                        icon: Icons.location_on_rounded,
                        color: tokens.danger,
                      ),
                    ],
                    height: 180,
                    interactive: true,
                  ),
                  OpenInMapButton(
                    target: MapTarget(
                      latitude: event.latitude!,
                      longitude: event.longitude!,
                      osmId: event.osmId,
                      label: event.name,
                    ),
                  ),
                ],
              ),
            ],
            if (event.citySlug != null ||
                (event.latitude != null && event.longitude != null)) ...[
              SizedBox(height: tokens.spaceLg),
              WeatherSummaryCard(
                citySlug: event.citySlug,
                lat: event.latitude,
                lon: event.longitude,
                locationName: event.name,
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

  Future<void> _addTicket() async {
    final result = await showTicketFormSheet(
      context: context,
      service: _service,
      eventId: widget.id,
    );
    if (result == true && mounted) _load();
  }

  Future<void> _deleteTicket(TravelEventTicket ticket) async {
    final deleted = await deleteUserTicketFlow(
      context: context,
      service: _service,
      ticket: ticket,
    );
    if (deleted && mounted) _load();
  }

  Future<void> _report() async {
    final event = _event;
    if (event == null) return;
    await showModerationRequestSheet(
      context,
      objectType: ModerationObjectType.travelEvent,
      objectId: event.id,
      objectName: event.name,
      isOwn: false,
    );
  }

  Widget _buildBodyWithFab() {
    if (_loading || _error != null || _event == null) return _buildBody();
    final event = _event!;
    final hasChat = event.conversationId != null;

    if (hasChat) {
      _ensureTabController(2);
      final showFab = _currentTabIndex == 0 && event.hastickets == '1';
      return Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: DesignTheme.of(context).primary,
            labelColor: DesignTheme.of(context).textHigh,
            unselectedLabelColor: DesignTheme.of(context).textLow,
            labelStyle: DesignTheme.of(
              context,
            ).bodyStyle(DesignTheme.of(context).textHigh),
            unselectedLabelStyle: DesignTheme.of(
              context,
            ).labelStyle(DesignTheme.of(context).textLow),
            tabs: const [
              Tab(text: 'Übersicht'),
              Tab(text: 'Chat'),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBody(),
                    ConversationBody(conversationId: event.conversationId!),
                  ],
                ),
                if (showFab)
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
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        _buildBody(),
        if (event.hastickets == '1')
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
              if (t.type == 'user')
                DesignIconButton(
                  icon: Icons.delete_outline_rounded,
                  onPressed: () => _deleteTicket(t),
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
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
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
