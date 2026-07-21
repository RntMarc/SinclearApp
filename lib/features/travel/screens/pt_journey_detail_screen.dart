import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/pt_models.dart';
import '../models/travel_models.dart';

class PtJourneyDetailScreen extends StatefulWidget {
  final String journeyId;

  const PtJourneyDetailScreen({super.key, required this.journeyId});

  @override
  State<PtJourneyDetailScreen> createState() => _PtJourneyDetailScreenState();
}

class _PtJourneyDetailScreenState extends State<PtJourneyDetailScreen> {
  PtSavedJourney? _journey;
  bool _loading = true;
  String? _error;
  bool _refreshing = false;
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
      final service = AppScope.of(context).publicTransport;
      final journey = await service.getJourney(widget.journeyId);
      if (!mounted) return;
      setState(() {
        _journey = journey;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load PT journey', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final service = AppScope.of(context).publicTransport;
      final journey = await service.refreshJourney(widget.journeyId);
      if (!mounted) return;
      setState(() {
        _journey = journey;
        _refreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echtzeitdaten aktualisiert')),
      );
    } catch (e, st) {
      developer.log('Refresh journey failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _refreshing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Aktualisieren: $e')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tokens = DesignTheme.of(context);
        return AlertDialog(
          title: const Text('Verbindung löschen'),
          content: const Text('Diese Verbindung wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Abbrechen', style: TextStyle(color: tokens.textLow)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Löschen', style: TextStyle(color: tokens.danger)),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      final service = AppScope.of(context).publicTransport;
      await service.deleteJourney(widget.journeyId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verbindung gelöscht')));
      Navigator.pop(context, true);
    } catch (e, st) {
      developer.log('Delete journey failed', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Löschen: $e')));
    }
  }

  Future<void> _attachToTrip() async {
    final travelService = AppScope.of(context).travel;

    List<TravelTrip> trips = [];
    try {
      final tripResponse = await travelService.list(limit: 100);
      trips = tripResponse.data;
    } catch (_) {}

    if (!mounted) return;

    String? selectedTripId = _journey?.tripId;

    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final tokens = DesignTheme.of(context);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLg,
                tokens.spaceLg,
                tokens.spaceLg,
                MediaQuery.of(context).padding.bottom + tokens.spaceLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignText(
                    'An Reise anheften',
                    style: DesignTextStyle.subtitle,
                    color: tokens.textHigh,
                  ),
                  SizedBox(height: tokens.spaceMd),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTripId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(tokens.radiusMd),
                      ),
                      hintText: 'Keine Reise',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Keine Reise'),
                      ),
                      ...trips.map(
                        (trip) => DropdownMenuItem(
                          value: trip.id,
                          child: Text(trip.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setSheetState(() {
                      selectedTripId = v;
                    }),
                  ),
                  SizedBox(height: tokens.spaceLg),
                  SizedBox(
                    width: double.infinity,
                    child: DesignButton(
                      label: 'Speichern',
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _updateTripId(selectedTripId);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateTripId(String? tripId) async {
    // TODO: Replace with actual PATCH call once
    //       PATCH /public-transport/journeys/{id} is available in the API.
    //       See doc/pt_plan.md section 2.
    // For now we cannot update tripId after save. The user should set tripId
    // when first saving the journey.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Nachträgliches Anheften/Lösen wird unterstützt, sobald der '
          'PATCH-Endpunkt in der API verfügbar ist.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesignSurface(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              DesignSubpageHeader(
                title: 'Verbindungsdetails',
                leading: DesignIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  DesignIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: _refreshing ? null : _refresh,
                  ),
                  DesignIconButton(
                    icon: Icons.link_rounded,
                    onPressed: _attachToTrip,
                  ),
                  DesignIconButton(
                    icon: Icons.delete_rounded,
                    onPressed: _delete,
                  ),
                ],
              ),
              Expanded(child: _buildBody(tokens)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(DesignTokens tokens) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesignText(
              'Fehler beim Laden',
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
      );
    }

    final journey = _journey!;
    final mode = journey.legs.isNotEmpty ? journey.legs.first.mode : 'RAIL';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        0,
        tokens.spaceLg,
        tokens.spaceXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(journey, mode, tokens),
          SizedBox(height: tokens.spaceLg),
          if (journey.tripId != null) ...[
            _buildTripBadge(journey.tripId!, tokens),
            SizedBox(height: tokens.spaceLg),
          ],
          DesignText(
            'Verlauf',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          _buildLegTimeline(journey.legs, tokens),
        ],
      ),
    );
  }

  Widget _buildHeader(
    PtSavedJourney journey,
    String mode,
    DesignTokens tokens,
  ) {
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_modeIcon(mode), color: tokens.primary, size: 28),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignText(
                  '${journey.fromStationName} \u2192 ${journey.toStationName}',
                  style: DesignTextStyle.subtitle,
                  color: tokens.textHigh,
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMd),
          _infoRow(
            Icons.schedule_rounded,
            '${formatDateTime(journey.departureTime)} \u2013 ${formatTime(journey.arrivalTime)}',
            tokens,
          ),
          SizedBox(height: tokens.spaceXs),
          _infoRow(
            Icons.timer_rounded,
            _formatDuration(journey.duration),
            tokens,
          ),
          SizedBox(height: tokens.spaceXs),
          _infoRow(
            Icons.transfer_within_a_station_rounded,
            '${journey.transfers} Umstieg${journey.transfers == 1 ? '' : 'e'}',
            tokens,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, DesignTokens tokens) {
    return Row(
      children: [
        Icon(icon, size: 16, color: tokens.textLow),
        SizedBox(width: tokens.spaceSm),
        DesignText(text, style: DesignTextStyle.body, color: tokens.textLow),
      ],
    );
  }

  Widget _buildTripBadge(String tripId, DesignTokens tokens) {
    return DesignCard(
      child: Row(
        children: [
          Icon(Icons.flight_rounded, color: tokens.primary, size: 20),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: DesignText(
              'An Reise angeheftet',
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
          ),
          DesignIconButton(
            icon: Icons.link_off_rounded,
            onPressed: () => _updateTripId(null),
          ),
        ],
      ),
    );
  }

  Widget _buildLegTimeline(List<PtLeg> legs, DesignTokens tokens) {
    return Column(
      children: List.generate(legs.length, (index) {
        final leg = legs[index];
        final isLast = index == legs.length - 1;
        return _LegTile(leg: leg, isLast: isLast);
      }),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }

  IconData _modeIcon(String mode) {
    switch (mode.toUpperCase()) {
      case 'RAIL':
      case 'TRAIN':
        return Icons.train_rounded;
      case 'BUS':
        return Icons.directions_bus_rounded;
      case 'TRAM':
        return Icons.tram_rounded;
      case 'SUBWAY':
        return Icons.subway_rounded;
      case 'WALK':
        return Icons.directions_walk_rounded;
      case 'FERRY':
        return Icons.directions_ferry_rounded;
      default:
        return Icons.directions_transit_rounded;
    }
  }
}

class _LegTile extends StatelessWidget {
  const _LegTile({required this.leg, required this.isLast});

  final PtLeg leg;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final color = leg.cancelled
        ? tokens.danger
        : leg.realTimeState == 'UPDATED'
        ? tokens.warning
        : tokens.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: tokens.divider)),
              ],
            ),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : tokens.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _modeIcon(leg.mode),
                        size: 16,
                        color: tokens.textHigh,
                      ),
                      SizedBox(width: tokens.spaceXs),
                      Expanded(
                        child: DesignText(
                          leg.lineName ?? leg.mode,
                          style: DesignTextStyle.body,
                          color: tokens.textHigh,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceXs),
                  if (leg.fromStationName != null)
                    DesignText(
                      leg.fromStationName!,
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                    ),
                  if (leg.plannedDeparture != null)
                    DesignText(
                      'Abfahrt: ${formatTime(leg.plannedDeparture!)}${leg.departurePlatform != null ? ' (Gleis ${leg.departurePlatform})' : ''}',
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                    ),
                  if (leg.departureDelay != null && leg.departureDelay! > 0)
                    DesignText(
                      '+${leg.departureDelay! ~/ 60} Min. Verspätung',
                      style: DesignTextStyle.label,
                      color: tokens.danger,
                    ),
                  SizedBox(height: tokens.spaceXs),
                  if (leg.toStationName != null)
                    DesignText(
                      leg.toStationName!,
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                    ),
                  if (leg.plannedArrival != null)
                    DesignText(
                      'Ankunft: ${formatTime(leg.plannedArrival!)}${leg.arrivalPlatform != null ? ' (Gleis ${leg.arrivalPlatform})' : ''}',
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                    ),
                  if (leg.arrivalDelay != null && leg.arrivalDelay! > 0)
                    DesignText(
                      '+${leg.arrivalDelay! ~/ 60} Min. Verspätung',
                      style: DesignTextStyle.label,
                      color: tokens.danger,
                    ),
                  if (leg.cancelled)
                    DesignText(
                      'Ausgefallen',
                      style: DesignTextStyle.label,
                      color: tokens.danger,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _modeIcon(String mode) {
    switch (mode.toUpperCase()) {
      case 'RAIL':
      case 'TRAIN':
        return Icons.train_rounded;
      case 'BUS':
        return Icons.directions_bus_rounded;
      case 'TRAM':
        return Icons.tram_rounded;
      case 'SUBWAY':
        return Icons.subway_rounded;
      case 'WALK':
        return Icons.directions_walk_rounded;
      case 'FERRY':
        return Icons.directions_ferry_rounded;
      default:
        return Icons.directions_transit_rounded;
    }
  }
}
