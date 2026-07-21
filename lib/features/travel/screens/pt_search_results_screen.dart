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

class PtSearchResultsScreen extends StatefulWidget {
  const PtSearchResultsScreen({
    required this.fromStation,
    required this.toStation,
    required this.departure,
    this.arriveBy = false,
    this.maxTransfers = 5,
    this.results = 5,
    super.key,
  });

  final PtStation fromStation;
  final PtStation toStation;
  final DateTime departure;
  final bool arriveBy;
  final int maxTransfers;
  final int results;

  @override
  State<PtSearchResultsScreen> createState() => _PtSearchResultsScreenState();
}

class _PtSearchResultsScreenState extends State<PtSearchResultsScreen> {
  List<PtJourneySearchResult>? _results;
  bool _loading = true;
  String? _error;
  bool _isSaving = false;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _search();
    }
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = AppScope.of(context).publicTransport;
      final response = await service.findJourneys(
        from: widget.fromStation.id,
        to: widget.toStation.id,
        departure: toApiDate(widget.departure),
        arriveBy: widget.arriveBy,
        results: widget.results,
        maxTransfers: widget.maxTransfers,
      );
      if (!mounted) return;
      setState(() {
        _results = response.data;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('PT search failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showSaveSheet(PtJourneySearchResult result) async {
    final travelService = AppScope.of(context).travel;

    List<TravelTrip> trips = [];
    try {
      final tripResponse = await travelService.list(limit: 100);
      trips = tripResponse.data;
    } catch (_) {}

    if (!mounted) return;

    String? selectedTripId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                    'Verbindung speichern',
                    style: DesignTextStyle.subtitle,
                    color: tokens.textHigh,
                  ),
                  SizedBox(height: tokens.spaceMd),
                  _buildResultSummary(result),
                  SizedBox(height: tokens.spaceLg),
                  if (trips.isNotEmpty) ...[
                    DesignText(
                      'Reise zuordnen (optional)',
                      style: DesignTextStyle.body,
                      color: tokens.textHigh,
                    ),
                    SizedBox(height: tokens.spaceSm),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTripId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                        ),
                        hintText: 'Keine Reise zuordnen',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: DesignText(
                            'Keine Reise',
                            style: DesignTextStyle.body,
                            color: tokens.textLow,
                          ),
                        ),
                        ...trips.map(
                          (trip) => DropdownMenuItem(
                            value: trip.id,
                            child: DesignText(
                              trip.name,
                              style: DesignTextStyle.body,
                              color: tokens.textHigh,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setSheetState(() {
                        selectedTripId = v;
                      }),
                    ),
                    SizedBox(height: tokens.spaceLg),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: DesignButton(
                      label: _isSaving ? 'Speichern...' : 'Speichern',
                      icon: Icons.bookmark_rounded,
                      onPressed: _isSaving
                          ? null
                          : () => _saveFromSheet(
                              sheetContext,
                              result,
                              selectedTripId,
                            ),
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

  Widget _buildResultSummary(PtJourneySearchResult result) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            '${widget.fromStation.name} \u2192 ${widget.toStation.name}',
            style: DesignTextStyle.body,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceXs),
          if (result.departureTime != null && result.arrivalTime != null)
            DesignText(
              '${formatDateTime(result.departureTime!)} \u2013 ${formatDateTime(result.arrivalTime!)}',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          SizedBox(height: tokens.spaceXs),
          DesignText(
            'Dauer: ${_formatDuration(result.duration)} \u2022 ${result.transfers} Umstieg${result.transfers == 1 ? '' : 'e'}',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceSm),
          for (final leg in result.legs) ...[
            Row(
              children: [
                Icon(_modeIcon(leg.mode), size: 16, color: tokens.primary),
                SizedBox(width: tokens.spaceXs),
                Expanded(
                  child: DesignText(
                    leg.lineName != null
                        ? '${leg.lineName}: ${leg.fromStationName ?? ""} \u2192 ${leg.toStationName ?? ""}'
                        : '${leg.fromStationName ?? ""} \u2192 ${leg.toStationName ?? ""}',
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceXs),
          ],
        ],
      ),
    );
  }

  Future<void> _saveFromSheet(
    BuildContext sheetContext,
    PtJourneySearchResult result,
    String? tripId,
  ) async {
    setState(() => _isSaving = true);

    if (result.legs.isEmpty) {
      if (!sheetContext.mounted) return;
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Keine Fahrtabschnitte vorhanden')),
      );
      setState(() => _isSaving = false);
      return;
    }

    try {
      final service = AppScope.of(sheetContext).publicTransport;
      final legMaps = result.legs.map((leg) {
        final json = leg.toJson();
        json['fromStationId'] ??= widget.fromStation.id;
        json['fromStationName'] ??= widget.fromStation.name;
        json['toStationId'] ??= widget.toStation.id;
        json['toStationName'] ??= widget.toStation.name;
        return json;
      }).toList();
      final request = PtSaveJourneyRequest(
        tripId: tripId,
        fromStationId: widget.fromStation.id,
        fromStationName: widget.fromStation.name,
        toStationId: widget.toStation.id,
        toStationName: widget.toStation.name,
        departureTime: toApiDate(result.departureTime ?? widget.departure),
        arrivalTime: toApiDate(result.arrivalTime ?? widget.departure),
        duration: result.duration,
        transfers: result.transfers,
        legs: legMaps,
      );
      await service.saveJourney(request);
      if (!sheetContext.mounted) return;
      Navigator.pop(sheetContext);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, st) {
      developer.log('Save journey failed', error: e, stackTrace: st);
      if (!sheetContext.mounted) return;
      ScaffoldMessenger.of(
        sheetContext,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Speichern: $e')));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            DesignSubpageHeader(
              title: 'Suchergebnisse',
              leading: DesignIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(child: _buildBody(tokens)),
          ],
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
              'Fehler bei der Suche',
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceMd),
            DesignButton(
              variant: DesignButtonVariant.outlined,
              label: 'Erneut versuchen',
              onPressed: _search,
            ),
          ],
        ),
      );
    }

    if (_results == null || _results!.isEmpty) {
      return Center(
        child: DesignText(
          'Keine Verbindungen gefunden',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, 0, 0, tokens.spaceXl),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final result = _results![index];
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            0,
            tokens.spaceLg,
            tokens.spaceXs,
          ),
          child: _ResultCard(
            result: result,
            onTap: () => _showSaveSheet(result),
          ),
        );
      },
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.onTap});

  final PtJourneySearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_transit_rounded,
                color: tokens.primary,
                size: 20,
              ),
              SizedBox(width: tokens.spaceSm),
              if (result.departureTime != null && result.arrivalTime != null)
                Expanded(
                  child: DesignText(
                    '${formatTime(result.departureTime!)} \u2013 ${formatTime(result.arrivalTime!)}',
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                ),
            ],
          ),
          SizedBox(height: tokens.spaceXs),
          DesignText(
            '${_formatDuration(result.duration)} \u2022 ${result.transfers} Umstieg${result.transfers == 1 ? '' : 'e'}',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceXs),
          if (result.legs.isNotEmpty)
            Wrap(
              spacing: tokens.spaceXs,
              children: result.legs.map((leg) {
                return Chip(
                  avatar: Icon(
                    _modeIcon(leg.mode),
                    size: 16,
                    color: tokens.primary,
                  ),
                  label: Text(
                    leg.lineName ?? leg.mode,
                    style: const TextStyle(fontSize: 12),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
        ],
      ),
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
