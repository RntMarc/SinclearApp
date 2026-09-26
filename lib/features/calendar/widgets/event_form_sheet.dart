import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/time_zone_picker.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../user/models/user_models.dart';
import '../models/calendar_models.dart';

class EventFormSheet extends StatefulWidget {
  final CalendarEvent? event;

  /// Vorbelegtes Startdatum für neue Events (z. B. der im Kalender
  /// ausgewählte Tag). Wird von [event] überschrieben, falls gesetzt.
  final DateTime? initialDate;

  /// Vorbelegte IANA-Zeitzone für neue Events (i. d. R. die effektive
  /// Zeitzone des Nutzers).
  final String initialTimeZone;

  const EventFormSheet({
    super.key,
    this.event,
    this.initialDate,
    required this.initialTimeZone,
  });

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late bool _allDay;
  late String _timezone;
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _startWall;
  late DateTime _endWall;
  late int _visibility;
  final Set<String> _participantIds = {};
  List<UserBasePublic> _allUsers = const [];

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    final now = DateTime.now();
    final baseDate = widget.initialDate ?? now;

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _allDay = event?.allDay ?? false;
    _timezone = event?.timezone ?? widget.initialTimeZone;

    if (event != null && !event.allDay && event.startAt != null) {
      final start = instantToWallTime(event.startAt!, event.timezone);
      final end = instantToWallTime(event.startInstant, event.timezone);
      _startWall = start;
      _endWall = event.endAt != null
          ? instantToWallTime(event.endAt!, event.timezone)
          : start.add(const Duration(hours: 1));
      _startDate = DateTime(start.year, start.month, start.day);
      _endDate = DateTime(end.year, end.month, end.day);
    } else if (event != null) {
      final start = event.startDate ?? baseDate;
      final end = event.endDate ?? baseDate;
      _startDate = DateTime(start.year, start.month, start.day);
      _endDate = DateTime(end.year, end.month, end.day);
      _startWall = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        now.hour,
        now.minute,
      );
      _endWall = _startWall.add(const Duration(hours: 1));
    } else {
      _startDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
      _endDate = _startDate;
      _startWall = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        now.hour,
        now.minute,
      );
      _endWall = _startWall.add(const Duration(hours: 1));
    }

    _visibility = event?.visibility ?? 0;
    if (event != null) {
      _participantIds.addAll(event.participants.map((p) => p.id));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DesignText(
              _isEditing ? 'Termin bearbeiten' : 'Neuer Termin',
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceLg),
            DesignTextField(hint: 'Titel *', controller: _titleController),
            SizedBox(height: tokens.spaceMd),
            Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
              ),
            ),
            SizedBox(height: tokens.spaceLg),
            Row(
              children: [
                Expanded(
                  child: DesignText(
                    'Ganztägig',
                    style: DesignTextStyle.label,
                    color: tokens.textHigh,
                  ),
                ),
                Switch(
                  value: _allDay,
                  onChanged: (v) => setState(() => _allDay = v),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceSm),
            DesignText(
              'Zeitzone',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
            SizedBox(height: tokens.spaceXs),
            TimeZonePicker(
              value: _timezone,
              onChanged: (zone) => setState(() => _timezone = zone),
            ),
            SizedBox(height: tokens.spaceMd),
            _DateTimePicker(
              label: 'Beginn',
              value: _allDay ? _startDate : _startWall,
              showTime: !_allDay,
              onChanged: (v) => setState(() {
                if (_allDay) {
                  _startDate = v;
                } else {
                  _startWall = v;
                }
              }),
            ),
            SizedBox(height: tokens.spaceMd),
            _DateTimePicker(
              label: 'Ende',
              value: _allDay ? _endDate : _endWall,
              showTime: !_allDay,
              onChanged: (v) => setState(() {
                if (_allDay) {
                  _endDate = v;
                } else {
                  _endWall = v;
                }
              }),
            ),
            SizedBox(height: tokens.spaceLg),
            DesignText(
              'Sichtbarkeit',
              style: DesignTextStyle.label,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceXs),
            _VisibilitySelector(
              value: _visibility,
              onChanged: (v) => setState(() => _visibility = v),
            ),
            SizedBox(height: tokens.spaceMd),
            DesignText(
              'Teilnehmer',
              style: DesignTextStyle.label,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceXs),
            _ParticipantChips(
              participantIds: _participantIds,
              allUsers: _allUsers,
              onRemove: (id) => setState(() => _participantIds.remove(id)),
              onAdd: _pickParticipants,
            ),
            SizedBox(height: tokens.spaceLg),
            SizedBox(
              width: double.infinity,
              child: DesignButton(
                label: _isEditing ? 'Speichern' : 'Erstellen',
                variant: DesignButtonVariant.filled,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickParticipants() async {
    if (_allUsers.isEmpty) {
      _allUsers = await AppScope.of(context).user.listAll();
    }
    if (!mounted) return;

    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (ctx) => _UserPickerSheet(
        users: _allUsers,
        selected: Set.from(_participantIds),
      ),
    );

    if (selected != null) {
      setState(
        () => _participantIds
          ..clear()
          ..addAll(selected),
      );
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    final result = <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'allDay': _allDay,
      'timezone': _timezone,
      'visibility': _visibility,
      'participantIds': _participantIds.toList(),
    };

    if (_allDay) {
      final startDate = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
      );
      final endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);
      if (endDate.isBefore(startDate)) {
        _showError('Das Enddatum darf nicht vor dem Startdatum liegen.');
        return;
      }
      result['startDate'] = startDate;
      result['endDate'] = endDate;
    } else {
      if (!_endWall.isAfter(_startWall)) {
        _showError('Das Ende muss nach dem Beginn liegen.');
        return;
      }
      result['startAt'] = _startWall;
      result['endAt'] = _endWall;
    }

    Navigator.of(context).pop(result);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime value;
  final bool showTime;
  final ValueChanged<DateTime> onChanged;

  const _DateTimePicker({
    required this.label,
    required this.value,
    this.showTime = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(label, style: DesignTextStyle.label, color: tokens.textLow),
        SizedBox(height: tokens.spaceXs),
        Row(
          children: [
            Expanded(
              flex: showTime ? 3 : 1,
              child: DesignButton(
                label: DateFormat('dd.MM.yyyy').format(value),
                variant: DesignButtonVariant.outlined,
                icon: Icons.calendar_today_rounded,
                onPressed: () => _pickDate(context),
              ),
            ),
            if (showTime) ...[
              SizedBox(width: tokens.spaceSm),
              Expanded(
                flex: 2,
                child: DesignButton(
                  label: DateFormat('HH:mm').format(value),
                  variant: DesignButtonVariant.outlined,
                  icon: Icons.access_time_rounded,
                  onPressed: () => _pickTime(context),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      onChanged(DateTime(picked.year, picked.month, picked.day, value.hour, value.minute));
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (picked != null) {
      onChanged(DateTime(value.year, value.month, value.day, picked.hour, picked.minute));
    }
  }
}

class _ParticipantChips extends StatelessWidget {
  final Set<String> participantIds;
  final List<UserBasePublic> allUsers;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  const _ParticipantChips({
    required this.participantIds,
    required this.allUsers,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final lookup = {for (final u in allUsers) u.id: u};
    final selected = participantIds
        .map((id) => lookup[id])
        .whereType<UserBasePublic>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (participantIds.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSm),
            child: Wrap(
              spacing: tokens.spaceXs,
              runSpacing: tokens.spaceXs,
              children: selected
                  .map(
                    (user) => Chip(
                      avatar: DesignAvatar(
                        imageUrl: user.image,
                        name: user.displayName,
                        size: 24,
                      ),
                      label: Text(user.displayName),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => onRemove(user.id),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
          ),
        DesignButton(
          label: 'Teilnehmer auswählen',
          variant: DesignButtonVariant.outlined,
          icon: Icons.person_add_rounded,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _UserPickerSheet extends StatefulWidget {
  final List<UserBasePublic> users;
  final Set<String> selected;

  const _UserPickerSheet({required this.users, required this.selected});

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  late Set<String> _selected;
  late String _query;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selected);
    _query = '';
  }

  List<UserBasePublic> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.users;
    return widget.users
        .where(
          (u) =>
              u.displayName.toLowerCase().contains(q) ||
              (u.email?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'Teilnehmer auswählen',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          TextField(
            decoration: InputDecoration(
              hintText: 'Suchen...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMd),
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          SizedBox(height: tokens.spaceMd),
          SizedBox(
            height: 300,
            child: ListView(
              children: _filtered
                  .map(
                    (user) => ListTile(
                      leading: DesignAvatar(
                        imageUrl: user.image,
                        name: user.displayName,
                        size: 36,
                      ),
                      title: Text(user.displayName),
                      subtitle: user.email != null ? Text(user.email!) : null,
                      trailing: Checkbox(
                        value: _selected.contains(user.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selected.add(user.id);
                            } else {
                              _selected.remove(user.id);
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (_selected.contains(user.id)) {
                            _selected.remove(user.id);
                          } else {
                            _selected.add(user.id);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          SizedBox(height: tokens.spaceMd),
          SizedBox(
            width: double.infinity,
            child: DesignButton(
              label: 'Bestätigen (${_selected.length})',
              variant: DesignButtonVariant.filled,
              onPressed: () => Navigator.pop(context, _selected),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilitySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _VisibilitySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return Row(
      children: [
        _visButton(tokens, 0, 'Privat', Icons.lock_rounded),
        SizedBox(width: tokens.spaceSm),
        _visButton(tokens, 1, 'Öffentlich', Icons.public_rounded),
        SizedBox(width: tokens.spaceSm),
        _visButton(tokens, 2, 'Freunde', Icons.people_rounded),
      ],
    );
  }

  Widget _visButton(DesignTokens tokens, int v, String label, IconData icon) {
    final selected = value == v;
    return Expanded(
      child: DesignButton(
        label: label,
        icon: icon,
        variant: selected
            ? DesignButtonVariant.filled
            : DesignButtonVariant.outlined,
        onPressed: () => onChanged(v),
      ),
    );
  }
}
