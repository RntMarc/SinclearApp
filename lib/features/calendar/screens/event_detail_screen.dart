import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../models/calendar_models.dart';
import '../services/calendar_service.dart';
import '../widgets/event_form_sheet.dart';

class EventDetailScreen extends StatefulWidget {
  final String id;

  const EventDetailScreen({super.key, required this.id});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  CalendarService get _service => AppScope.of(context).calendar;

  CalendarEvent? _event;
  bool _hasLoaded = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

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
      final event = await _service.get(widget.id);
      if (mounted) {
        setState(() {
          _event = event;
          _loading = false;
        });
      }
    } catch (e, st) {
      developer.log('Failed to load event', error: e, stackTrace: st);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _edit() async {
    if (_event == null) return;

    final result = await showDesignSheet<Map<String, dynamic>>(
      context: context,
      child: EventFormSheet(event: _event),
    );

    if (result == null || !mounted) return;

    try {
      await _service.update(
        _event!.id,
        title: result['title'] as String,
        description: result['description'] as String?,
        startTime: result['startTime'] as DateTime,
        endTime: result['endTime'] as DateTime,
        visibility: result['visibility'] as int,
      );
      _load();
    } catch (e, st) {
      developer.log('Failed to update event', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern')));
      }
    }
  }

  Future<void> _delete() async {
    if (_event == null) return;

    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'Termin löschen',
            style: DesignTextStyle.subtitle,
            color: DesignTheme.of(context).textHigh,
          ),
          SizedBox(height: DesignTheme.of(context).spaceMd),
          DesignText(
            '"${_event!.title}" wirklich löschen?',
            style: DesignTextStyle.body,
            color: DesignTheme.of(context).textLow,
          ),
          SizedBox(height: DesignTheme.of(context).spaceLg),
          Row(
            children: [
              Expanded(
                child: DesignButton(
                  label: 'Abbrechen',
                  variant: DesignButtonVariant.outlined,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              SizedBox(width: DesignTheme.of(context).spaceMd),
              Expanded(
                child: DesignButton(
                  label: 'Löschen',
                  variant: DesignButtonVariant.filled,
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
      await _service.delete(_event!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      developer.log('Failed to delete event', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fehler beim Löschen')));
      }
    }
  }

  String _visibilityLabel(int visibility) {
    switch (visibility) {
      case 0:
        return 'Privat';
      case 1:
        return 'Öffentlich';
      case 2:
        return 'Enge Freunde';
      default:
        return 'Unbekannt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return DesignSurface(
        child: Column(
          children: [
            DesignAppBar(
              leading: DesignIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
              ),
              title: 'Termin',
            ),
            Expanded(
              child: Center(child: CircularProgressIndicator(color: tokens.primary)),
            ),
          ],
        ),
      );
    }

    if (_error != null || _event == null) {
      return DesignSurface(
        child: Column(
          children: [
            DesignAppBar(
              leading: DesignIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
              ),
              title: 'Termin',
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DesignText(
                      'Fehler beim Laden des Termins',
                      style: DesignTextStyle.body,
                      color: tokens.textLow,
                    ),
                    SizedBox(height: tokens.spaceMd),
                    DesignButton(
                      label: 'Erneut versuchen',
                      variant: DesignButtonVariant.filled,
                      onPressed: _load,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final event = _event!;

    return DesignSurface(
      child: Column(
        children: [
          DesignAppBar(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: event.title,
            actions: [
              DesignIconButton(
                icon: Icons.edit_rounded,
                onPressed: _edit,
              ),
              DesignIconButton(
                icon: Icons.delete_rounded,
                onPressed: _delete,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                DesignText(
                  event.title,
                  style: DesignTextStyle.subtitle,
                  color: tokens.textHigh,
                ),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  SizedBox(height: tokens.spaceMd),
                  DesignText(
                    event.description!,
                    style: DesignTextStyle.body,
                    color: tokens.textLow,
                  ),
                ],
                SizedBox(height: tokens.spaceLg),
                _infoRow(
                  tokens: tokens,
                  icon: Icons.access_time_rounded,
                  label: 'Zeitraum',
                  value: formatDateRange(event.startTime, event.endTime),
                ),
                SizedBox(height: tokens.spaceSm),
                _infoRow(
                  tokens: tokens,
                  icon: Icons.visibility_rounded,
                  label: 'Sichtbarkeit',
                  value: _visibilityLabel(event.visibility),
                ),
                SizedBox(height: tokens.spaceSm),
                _infoRow(
                  tokens: tokens,
                  icon: Icons.person_rounded,
                  label: 'Erstellt von',
                  value: event.creatorId,
                ),
                if (event.participants.isNotEmpty) ...[
                  SizedBox(height: tokens.spaceLg),
                  DesignText(
                    'Teilnehmer (${event.participants.length})',
                    style: DesignTextStyle.label,
                    color: tokens.textHigh,
                  ),
                  SizedBox(height: tokens.spaceSm),
                  ...event.participants.map(
                    (p) => DesignListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: tokens.primary,
                          borderRadius: BorderRadius.circular(tokens.radiusPill),
                        ),
                        child: Center(
                          child: DesignText(
                            p.displayName[0].toUpperCase(),
                            style: DesignTextStyle.body,
                            color: tokens.textHigh,
                          ),
                        ),
                      ),
                      title: p.displayName,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ],
          ),
        ),
      ),
      ],
    ),
    );
  }
}

Widget _infoRow({
  required DesignTokens tokens,
  required IconData icon,
  required String label,
  required String value,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: tokens.textLow),
      SizedBox(width: tokens.spaceMd),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(label, style: DesignTextStyle.label, color: tokens.textLow),
          DesignText(value, style: DesignTextStyle.body, color: tokens.textHigh),
        ],
      ),
    ],
  );
}
