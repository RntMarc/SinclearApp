import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
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
import '../widgets/event_banner_picker.dart';
import '../widgets/travel_timing_fields.dart';

/// Formular zum Erstellen/Bearbeiten eines Reise-Events oder
/// Standalone-Events. Mit [tripId] gesetzt wird ein Reise-Event bearbeitet,
/// sonst ein Standalone-Event.
class EventFormScreen extends StatefulWidget {
  final String? tripId;
  final String? eventId;

  const EventFormScreen({super.key, this.tripId, this.eventId});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  TravelService get _service => AppScope.of(context).travel;

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _url = TextEditingController();
  final _organizer = TextEditingController();
  final _address = TextEditingController();
  final _ticket = TextEditingController();
  final _ticketUrl = TextEditingController();

  TravelTimingInput _timing = const TravelTimingInput(
    allDay: true,
    timezone: 'UTC',
  );

  bool _hasTickets = false;
  String? _banner;
  bool _bannerTouched = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.eventId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loading) return;
    _loading = false;
    _timing = TravelTimingInput(
      allDay: false,
      timezone: AppScope.of(context).timeZones.effective,
    );
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    try {
      final event = await _service.getEventUnified(widget.eventId!);
      if (!mounted) return;
      setState(() {
        _name.text = event.name;
        _description.text = event.description ?? '';
        _url.text = event.url ?? '';
        _organizer.text = event.organizer ?? '';
        _address.text = event.address ?? '';
        _ticket.text = event.ticket ?? '';
        _ticketUrl.text = event.ticketUrl ?? '';
        _hasTickets = event.hastickets == '1';
        _banner = event.image;
        _timing = TravelTimingInput(
          allDay: event.allDay,
          timezone: event.timezone,
          startDate: event.startDate,
          endDate: event.endDate,
          startAt: event.startAt != null
              ? instantToWallTime(event.startAt!, event.timezone)
              : null,
          endAt: event.endAt != null
              ? instantToWallTime(event.endAt!, event.timezone)
              : null,
        );
      });
    } catch (e, st) {
      developer.log('Failed to load event', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = 'Event konnte nicht geladen werden.');
    }
  }

  Future<void> _pickBanner() async {
    final banner = await pickEventBanner(context);
    if (banner == null || !mounted) return;
    setState(() {
      _banner = banner;
      _bannerTouched = true;
    });
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
      if (widget.tripId != null) {
        if (_isEdit) {
          await _service.updateTripEvent(
            widget.tripId!,
            widget.eventId!,
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
            url: _url.text.trim(),
            organizer: _organizer.text.trim(),
            address: _address.text.trim(),
            image: _bannerTouched ? _banner : null,
          );
        } else {
          await _service.createTripEvent(
            widget.tripId!,
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
            url: _url.text.trim().isEmpty ? null : _url.text.trim(),
            organizer: _organizer.text.trim().isEmpty
                ? null
                : _organizer.text.trim(),
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
            image: _banner,
          );
        }
      } else {
        if (_isEdit) {
          await _service.updateStandaloneEvent(
            widget.eventId!,
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
            url: _url.text.trim(),
            organizer: _organizer.text.trim(),
            address: _address.text.trim(),
            image: _bannerTouched ? _banner : null,
          );
        } else {
          await _service.createStandaloneEvent(
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
            url: _url.text.trim().isEmpty ? null : _url.text.trim(),
            organizer: _organizer.text.trim().isEmpty
                ? null
                : _organizer.text.trim(),
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
            image: _banner,
          );
        }
      }
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      developer.log('Failed to save event', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(travelErrorMessage(e))));
    } catch (e, st) {
      developer.log('Failed to save event', error: e, stackTrace: st);
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
    _url.dispose();
    _organizer.dispose();
    _address.dispose();
    _ticket.dispose();
    _ticketUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: _isEdit ? 'Event bearbeiten' : 'Neues Event',
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
                          hint: 'Name des Events',
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
                        _label(tokens, 'Banner-Bild'),
                        SizedBox(height: tokens.spaceSm),
                        _bannerSection(tokens),
                        SizedBox(height: tokens.spaceXl),
                        _label(tokens, 'Details'),
                        SizedBox(height: tokens.spaceSm),
                        DesignTextField(
                          hint: 'Ort/Adresse',
                          controller: _address,
                        ),
                        SizedBox(height: tokens.spaceMd),
                        DesignTextField(
                          hint: 'Veranstalter (optional)',
                          controller: _organizer,
                        ),
                        SizedBox(height: tokens.spaceMd),
                        DesignTextField(
                          hint: 'Link (optional)',
                          controller: _url,
                        ),
                        SizedBox(height: tokens.spaceXl),
                        _label(tokens, 'Tickets'),
                        SizedBox(height: tokens.spaceSm),
                        _ticketSection(tokens),
                        SizedBox(height: tokens.spaceXxl),
                        DesignButton(
                          label: _isEdit ? 'Speichern' : 'Erstellen',
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

  Widget _bannerSection(DesignTokens tokens) {
    if (!eventBannerSupported) {
      return DesignText(
        'Auf diesem Gerät nicht verfügbar.',
        style: DesignTextStyle.label,
        color: tokens.textLow,
      );
    }
    final provider = resolveImageProvider(_banner);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            child: AspectRatio(
              aspectRatio: 3.5 / 1,
              child: Image(
                image: provider,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          SizedBox(height: tokens.spaceMd),
        ],
        DesignButton(
          label: _banner != null ? 'Bild ändern' : 'Bild auswählen',
          variant: DesignButtonVariant.outlined,
          icon: Icons.image_rounded,
          onPressed: _pickBanner,
        ),
      ],
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
                'Tickets für das Event verwalten',
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
              onPressed: _load,
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
