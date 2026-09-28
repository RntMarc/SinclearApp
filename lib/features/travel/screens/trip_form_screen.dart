import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../services/travel_service.dart';
import '../travel_error_messages.dart';
import '../widgets/travel_timing_fields.dart';

/// Formular zum Erstellen/Bearbeiten einer Reise.
class TripFormScreen extends StatefulWidget {
  final String? tripId;

  const TripFormScreen({super.key, this.tripId});

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  TravelService get _service => AppScope.of(context).travel;

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _ticket = TextEditingController();
  final _ticketUrl = TextEditingController();

  TravelTimingInput _timing = const TravelTimingInput(
    allDay: true,
    timezone: 'UTC',
  );

  bool _hasTickets = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading) return;
    _loading = false;
    _timing = TravelTimingInput(
      allDay: true,
      timezone: AppScope.of(context).timeZones.effective,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
    );
    if (widget.tripId != null) _load();
  }

  Future<void> _load() async {
    try {
      final trip = await _service.getTrip(widget.tripId!);
      if (!mounted) return;
      setState(() {
        _name.text = trip.name;
        _description.text = trip.description ?? '';
        _ticket.text = trip.ticket ?? '';
        _ticketUrl.text = trip.ticketUrl ?? '';
        _hasTickets = trip.hastickets == '1';
        _timing = TravelTimingInput(
          allDay: trip.allDay,
          timezone: trip.timezone,
          startDate: trip.startDate,
          endDate: trip.endDate,
          startAt: trip.startAt != null
              ? instantToWallTime(trip.startAt!, trip.timezone)
              : null,
          endAt: trip.endAt != null
              ? instantToWallTime(trip.endAt!, trip.timezone)
              : null,
        );
      });
    } catch (e, st) {
      developer.log('Failed to load trip', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Reise konnte nicht geladen werden.');
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Namen an.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.tripId == null) {
        await _service.createTrip(
          name: name,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          allDay: _timing.allDay,
          timezone: _timing.timezone,
          startDate: _timing.startDate,
          endDate: _timing.endDate,
          startAt: _timing.startAt,
          endAt: _timing.endAt,
          hastickets: _hasTickets,
          ticket: _ticket.text.trim().isEmpty ? null : _ticket.text.trim(),
          ticketUrl: _ticketUrl.text.trim().isEmpty
              ? null
              : _ticketUrl.text.trim(),
        );
      } else {
        await _service.updateTrip(
          widget.tripId!,
          name: name,
          description: _description.text.trim(),
          allDay: _timing.allDay,
          timezone: _timing.timezone,
          startDate: _timing.startDate,
          endDate: _timing.endDate,
          startAt: _timing.startAt,
          endAt: _timing.endAt,
          hastickets: _hasTickets,
          ticket: _ticket.text.trim(),
          ticketUrl: _ticketUrl.text.trim(),
        );
      }
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      developer.log('Failed to save trip', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(travelErrorMessage(e))));
    } catch (e, st) {
      developer.log('Failed to save trip', error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _ticket.dispose();
    _ticketUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final isEdit = widget.tripId != null;

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: isEdit ? 'Reise bearbeiten' : 'Neue Reise',
          ),
          Expanded(
            child: _error != null
                ? _errorView(tokens)
                : SingleChildScrollView(
                    padding: EdgeInsets.all(tokens.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(tokens, 'Name'),
                        SizedBox(height: tokens.spaceSm),
                        DesignTextField(
                          hint: 'Name der Reise',
                          controller: _name,
                        ),
                        SizedBox(height: tokens.spaceMd),
                        _label(tokens, 'Beschreibung'),
                        SizedBox(height: tokens.spaceSm),
                        DesignTextField(
                          hint: 'Beschreibung (optional)',
                          controller: _description,
                          maxLines: 3,
                        ),
                        SizedBox(height: tokens.spaceXl),
                        TravelTimingFields(
                          initial: _timing,
                          onChanged: (value) => _timing = value,
                        ),
                        SizedBox(height: tokens.spaceXl),
                        _label(tokens, 'Tickets'),
                        SizedBox(height: tokens.spaceSm),
                        _ticketSection(tokens),
                        SizedBox(height: tokens.spaceXxl),
                        DesignButton(
                          label: isEdit ? 'Speichern' : 'Erstellen',
                          fullWidth: true,
                          loading: _saving,
                          onPressed: _save,
                        ),
                        SizedBox(height: tokens.spaceXl),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _ticketSection(DesignTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DesignText(
                'Tickets für die Reise verwalten',
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: Switch(
                value: _hasTickets,
                activeThumbColor: tokens.primary,
                onChanged: (v) => setState(() => _hasTickets = v),
              ),
            ),
          ],
        ),
        if (_hasTickets) ...[
          SizedBox(height: tokens.spaceMd),
          DesignTextField(hint: 'Ticket-Informationen', controller: _ticket),
          SizedBox(height: tokens.spaceMd),
          DesignTextField(
            hint: 'Ticket-URL (optional)',
            controller: _ticketUrl,
          ),
        ],
      ],
    );
  }

  Widget _errorView(DesignTokens tokens) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(tokens.spaceXl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesignText(
              _error!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceMd),
            DesignButton(
              label: 'Erneut versuchen',
              variant: DesignButtonVariant.outlined,
              onPressed: widget.tripId == null ? () {} : _load,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(DesignTokens tokens, String text) {
    return DesignText(
      text,
      style: DesignTextStyle.label,
      color: tokens.textLow,
    );
  }
}
