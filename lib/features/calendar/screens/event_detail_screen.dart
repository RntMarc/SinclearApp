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
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../user/models/user_models.dart';
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

  bool _canEdit(CalendarEvent event) {
    final userId = AppScope.of(context).auth.userId;
    if (userId == null) return false;
    return userId == event.creatorId ||
        event.participants.any((p) => p.id == userId);
  }

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

  Future<void> _addParticipant() async {
    if (_event == null) return;
    final users = await AppScope.of(context).user.listAll();
    if (!mounted) return;

    final existingIds = {
      _event!.creatorId,
      ..._event!.participants.map((p) => p.id),
    };
    final available = users.where((u) => !existingIds.contains(u.id)).toList();

    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (ctx) => _SimpleUserPicker(users: available),
    );

    if (picked == null || !mounted) return;

    try {
      await _service.addParticipant(_event!.id, picked);
      _load();
    } catch (e, st) {
      developer.log('Failed to add participant', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fehler beim Hinzufügen')));
      }
    }
  }

  Future<void> _removeParticipant(String userId) async {
    if (_event == null) return;

    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'Teilnehmer entfernen?',
            style: DesignTextStyle.subtitle,
            color: DesignTheme.of(context).textHigh,
          ),
          SizedBox(height: DesignTheme.of(context).spaceMd),
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
                  label: 'Entfernen',
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
      await _service.removeParticipant(_event!.id, userId);
      _load();
    } catch (e, st) {
      developer.log('Failed to remove participant', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fehler beim Entfernen')));
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
            DesignSubpageHeader(
              leading: DesignIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
              ),
              title: 'Termin',
            ),
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: tokens.primary),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null || _event == null) {
      return DesignSurface(
        child: Column(
          children: [
            DesignSubpageHeader(
              leading: DesignIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
              ),
              title: 'Termin',
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
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
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: event.title,
            actions: [
              if (_canEdit(event))
                DesignIconButton(icon: Icons.edit_rounded, onPressed: _edit),
              if (_canEdit(event))
                DesignIconButton(
                  icon: Icons.delete_rounded,
                  onPressed: _delete,
                ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
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
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
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
                      value: event.creatorDisplayName ?? event.creatorId,
                    ),
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
                            borderRadius: BorderRadius.circular(
                              tokens.radiusPill,
                            ),
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
                        trailing: _canEdit(event) && p.id != event.creatorId
                            ? DesignIconButton(
                                icon: Icons.remove_circle_outline_rounded,
                                onPressed: () => _removeParticipant(p.id),
                              )
                            : null,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    if (_canEdit(event)) ...[
                      SizedBox(height: tokens.spaceMd),
                      DesignButton(
                        label: 'Teilnehmer hinzufügen',
                        variant: DesignButtonVariant.outlined,
                        icon: Icons.person_add_rounded,
                        onPressed: _addParticipant,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleUserPicker extends StatelessWidget {
  final List<UserBasePublic> users;

  const _SimpleUserPicker({required this.users});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'Teilnehmer hinzufügen',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          if (users.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceLg),
              child: DesignText(
                'Keine weiteren Nutzer verfügbar',
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.separated(
                itemCount: users.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tokens.primary,
                        borderRadius: BorderRadius.circular(tokens.radiusPill),
                      ),
                      child: Center(
                        child: DesignText(
                          user.displayName[0].toUpperCase(),
                          style: DesignTextStyle.body,
                          color: tokens.textHigh,
                        ),
                      ),
                    ),
                    title: DesignText(
                      user.displayName,
                      style: DesignTextStyle.body,
                      color: tokens.textHigh,
                    ),
                    trailing: DesignIconButton(
                      icon: Icons.add_circle_outline_rounded,
                      onPressed: () => Navigator.pop(context, user.id),
                    ),
                  );
                },
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
          DesignText(
            label,
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          DesignText(
            value,
            style: DesignTextStyle.body,
            color: tokens.textHigh,
          ),
        ],
      ),
    ],
  );
}
