import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_fab.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../moderation/models/moderation_models.dart';
import '../../moderation/widgets/moderation_request_sheet.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import '../services/trip_data_controller.dart';
import '../travel_error_messages.dart';
import '../widgets/manage_participants_sheet.dart';
import '../widgets/ticket_form_sheet.dart';
import '../widgets/trip_detail_widgets.dart';
import '../widgets/embedded_forum_view.dart';
import '../../chat/widgets/conversation_body.dart';

class TripDetailScreen extends StatefulWidget {
  final String id;

  const TripDetailScreen({super.key, required this.id});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with TickerProviderStateMixin {
  static final _log = Logger('trip_detail');
  TravelService get _service => AppScope.of(context).travel;

  bool _loading = true;
  String? _error;

  TravelTrip? _trip;
  TripDataController? _controller;
  bool _hasLoaded = false;

  TabController? _tabController;
  int _currentTabIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  /// Loads only the trip itself; every tab section loads its own data via
  /// [TripDataController] and fails independently.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final trip = await _service.getTrip(widget.id);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _controller = _createController();
        _loading = false;
      });
      unawaited(_markRead(trip));
    } catch (e, st) {
      _log.severe('Failed to load trip detail', e, st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Pull-to-refresh and post-action reload: keeps the current UI when the
  /// trip request fails and refetches every section via the controller.
  Future<void> _refresh() async {
    _controller?.refresh();
    if (mounted) setState(() {});
    try {
      final trip = await _service.getTrip(widget.id);
      if (!mounted) return;
      setState(() => _trip = trip);
    } catch (e, st) {
      _log.warning('Trip refresh failed; keeping current data', e, st);
    }
  }

  TripDataController _createController() {
    return TripDataController(
      service: _service,
      tripId: widget.id,
      currentUserId: AppScope.of(context).auth.userId,
    );
  }

  /// Markiert ungelesene Reise-Benachrichtigungen beim Öffnen als gelesen.
  Future<void> _markRead(TravelTrip trip) async {
    try {
      final scope = AppScope.of(context);
      final ids = scope.notification.unreadIdsForTrip(trip.id);
      if (ids.isEmpty) return;
      await scope.notification.markRead(
        ids,
        token: await scope.auth.getAccessToken(),
      );
    } catch (e, st) {
      _log.warning('markRead failed', e, st);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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

  Future<void> _addTicket() async {
    final result = await showTicketFormSheet(
      context: context,
      service: _service,
      tripId: widget.id,
    );
    if (result == true && mounted) _refresh();
  }

  Future<void> _report() async {
    final trip = _trip;
    if (trip == null) return;
    await showModerationRequestSheet(
      context,
      objectType: ModerationObjectType.travelTrip,
      objectId: trip.id,
      objectName: trip.name,
      isOwn: trip.canEdit,
    );
  }

  void _openMenu() {
    final trip = _trip;
    if (trip == null) return;
    final tokens = DesignTheme.of(context);
    showDesignSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            trip.name,
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          _menuTile(
            context,
            icon: Icons.edit_rounded,
            label: 'Bearbeiten',
            onTap: () async {
              Navigator.of(context).pop();
              final changed = await context.push<bool>(
                '/reisen/${trip.id}/bearbeiten',
              );
              if (changed == true && mounted) _refresh();
            },
          ),
          _menuTile(
            context,
            icon: Icons.group_rounded,
            label: 'Teilnehmer verwalten',
            onTap: () {
              Navigator.of(context).pop();
              _manageParticipants();
            },
          ),
          _menuTile(
            context,
            icon: Icons.event_rounded,
            label: 'Event hinzufügen',
            onTap: () async {
              Navigator.of(context).pop();
              final changed = await context.push<bool>(
                '/reisen/${trip.id}/events/neu',
              );
              if (changed == true && mounted) _refresh();
            },
          ),
          _menuTile(
            context,
            icon: Icons.hotel_rounded,
            label: 'Unterkunft hinzufügen',
            onTap: () async {
              Navigator.of(context).pop();
              final changed = await context.push<bool>(
                '/reisen/${trip.id}/unterkunft/neu',
              );
              if (changed == true && mounted) _refresh();
            },
          ),
          _menuTile(
            context,
            icon: Icons.delete_outline_rounded,
            label: 'Löschen',
            danger: true,
            onTap: () {
              Navigator.of(context).pop();
              _confirmDelete();
            },
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
      child: DesignButton(
        label: label,
        variant: danger ? DesignButtonVariant.ghost : DesignButtonVariant.text,
        icon: icon,
        fullWidth: true,
        onPressed: onTap,
      ),
    );
  }

  Future<void> _manageParticipants() async {
    final tripId = widget.id;
    await showManageParticipantsSheet(
      context: context,
      title: 'Teilnehmer',
      roleLabel: 'Reiseleiter',
      load: () async {
        final participants = await _service.getParticipants(tripId);
        return participants.data
            .map(
              (p) => TravelParticipantEntry(
                id: p.id,
                displayName: p.displayName,
                image: p.image,
                role: p.role,
              ),
            )
            .toList();
      },
      add: (userId) => _service.addTripParticipant(tripId, userId),
      remove: (userId) => _service.removeTripParticipant(tripId, userId),
      setRole: (userId, role) =>
          _service.setTripParticipantRole(tripId, userId, role),
      loadAccommodations: () async {
        final response = await _service.getAccommodations(tripId);
        return response.data;
      },
      assignAccommodation: (userId, accommodationId) =>
          _service.assignParticipantAccommodation(
            tripId,
            userId,
            accommodationId: accommodationId,
          ),
    );
    if (mounted) _refresh();
  }

  Future<void> _confirmDelete() async {
    final tokens = DesignTheme.of(context);
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'Reise löschen?',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Die Reise und alle zugehörigen Daten werden dauerhaft gelöscht.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceMd),
          Row(
            children: [
              Expanded(
                child: DesignButton(
                  label: 'Abbrechen',
                  variant: DesignButtonVariant.outlined,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: DesignButton(
                  label: 'Löschen',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deleteTrip(widget.id);
      if (mounted) context.go('/reisen');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(travelErrorMessage(e))));
    } catch (e, st) {
      _log.warning('Failed to delete trip', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Löschen.')));
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
            title: _trip?.name ?? 'Reise',
            actions: [
              if (_trip != null && _trip!.canEdit)
                DesignIconButton(
                  icon: Icons.more_vert_rounded,
                  onPressed: _openMenu,
                ),
              if (_trip != null)
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DesignText(
                  'Fehler beim Laden der Reisedetails',
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
      );
    }

    final trip = _trip;
    final controller = _controller;
    if (trip == null || controller == null) {
      return Center(
        child: DesignText(
          'Reise nicht gefunden',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }

    final auth = AppScope.of(context).auth;
    final currentUserId = auth.userId;

    final tabTitles = _getTabTitles(trip);
    final mapTabIndex = tabTitles.indexOf('Karte');

    final tabs = <Tab>[];
    final tabViews = <Widget>[];

    for (final title in tabTitles) {
      tabs.add(Tab(text: title));
      switch (title) {
        case 'Übersicht':
          tabViews.add(
            TripOverviewSection(
              trip: trip,
              controller: controller,
              currentUserId: currentUserId,
              onSelectMapTab: mapTabIndex != -1
                  ? () => _tabController?.animateTo(mapTabIndex)
                  : null,
            ),
          );
          break;
        case 'Forum':
          tabViews.add(EmbeddedForumView(forumId: trip.forumId!));
          break;
        case 'Chat':
          tabViews.add(ConversationBody(conversationId: trip.conversationId!));
          break;
        case 'Events':
          tabViews.add(
            TripEventsSection(
              controller: controller,
              currentUserId: currentUserId,
              onChanged: controller.refresh,
            ),
          );
          break;
        case 'Tickets':
          tabViews.add(
            TripTicketsSection(
              controller: controller,
              ticket: trip.ticket,
              ticketUrl: trip.ticketUrl,
            ),
          );
          break;
        case 'Zahlungen':
          tabViews.add(TripPaymentsSection(controller: controller));
          break;
        case 'Karte':
          tabViews.add(
            TripMapSection(
              controller: controller,
              currentUserId: currentUserId,
            ),
          );
          break;
      }
    }

    _ensureTabController(tabs.length);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: tokens.primary,
            labelColor: tokens.textHigh,
            unselectedLabelColor: tokens.textLow,
            labelStyle: tokens.bodyStyle(tokens.textHigh),
            unselectedLabelStyle: tokens.labelStyle(tokens.textLow),
            isScrollable: tabs.length > 3,
            tabs: tabs,
          ),
          Expanded(
            child: TabBarView(controller: _tabController, children: tabViews),
          ),
        ],
      ),
    );
  }

  /// Tab structure derives from trip metadata only, so no tab appears or
  /// disappears when the section data arrives.
  List<String> _getTabTitles(TravelTrip trip) {
    final titles = <String>['Übersicht'];
    if (trip.conversationId != null) titles.add('Chat');
    if (trip.forumId != null) titles.add('Forum');
    titles.add('Events');
    final hasTicketInfo =
        (trip.ticket != null && trip.ticket!.isNotEmpty) ||
        (trip.ticketUrl != null && trip.ticketUrl!.isNotEmpty) ||
        trip.hastickets == '1';
    // ponytail: ticket visibility relies on trip metadata only (the trip has
    // no ticket count); trips whose tickets exist only via the tickets
    // endpoint hide the tab until the API exposes a count.
    if (hasTicketInfo) titles.add('Tickets');
    if (trip.subscriptionCount > 0) titles.add('Zahlungen');
    titles.add('Karte');
    return titles;
  }

  Widget _buildBodyWithFab() {
    if (_loading || _error != null || _trip == null || _controller == null) {
      return _buildBody();
    }
    final controller = _controller!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tabTitles = _getTabTitles(_trip!);
        final ticketsTabIndex = tabTitles.indexOf('Tickets');
        final showFab =
            ticketsTabIndex != -1 &&
            _currentTabIndex == ticketsTabIndex &&
            _trip!.hastickets == '1';

        return Stack(
          children: [
            _buildBody(),
            if (showFab)
              Positioned(
                right: DesignTheme.of(context).spaceLg,
                bottom: DesignTheme.of(context).spaceLg,
                child: DesignFab(
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: _addTicket,
                  tooltip: 'Ticket hinzufügen',
                ),
              ),
          ],
        );
      },
    );
  }
}
