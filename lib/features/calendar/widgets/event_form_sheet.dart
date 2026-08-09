import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../user/models/user_models.dart';
import '../models/calendar_models.dart';

class EventFormSheet extends StatefulWidget {
  final CalendarEvent? event;

  const EventFormSheet({super.key, this.event});

  @override
  State<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<EventFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late int _visibility;
  final Set<String> _participantIds = {};
  List<UserBasePublic> _allUsers = const [];

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    final now = DateTime.now();

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _startDate = event?.startTime ?? now;
    _startTime = TimeOfDay.fromDateTime(event?.startTime ?? now);
    _endDate = event?.endTime ?? now.add(const Duration(hours: 1));
    _endTime = TimeOfDay.fromDateTime(
      event?.endTime ?? now.add(const Duration(hours: 1)),
    );
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
                scrollPadding: const EdgeInsets.only(bottom: 140.0),
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
            _DateTimePicker(
              label: 'Beginn',
              date: _startDate,
              time: _startTime,
              onDateChanged: (d) => setState(() => _startDate = d),
              onTimeChanged: (t) => setState(() => _startTime = t),
            ),
            SizedBox(height: tokens.spaceMd),
            _DateTimePicker(
              label: 'Ende',
              date: _endDate,
              time: _endTime,
              onDateChanged: (d) => setState(() => _endDate = d),
              onTimeChanged: (t) => setState(() => _endTime = t),
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

    final start = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Das Ende muss nach dem Beginn liegen.')),
      );
      return;
    }

    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'startTime': start,
      'endTime': end,
      'visibility': _visibility,
      'participantIds': _participantIds.toList(),
    });
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime date;
  final TimeOfDay time;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const _DateTimePicker({
    required this.label,
    required this.date,
    required this.time,
    required this.onDateChanged,
    required this.onTimeChanged,
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
              flex: 3,
              child: DesignButton(
                label: DateFormat('dd.MM.yyyy').format(date),
                variant: DesignButtonVariant.outlined,
                icon: Icons.calendar_today_rounded,
                onPressed: () => _pickDate(context),
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              flex: 2,
              child: DesignButton(
                label: time.format(context),
                variant: DesignButtonVariant.outlined,
                icon: Icons.access_time_rounded,
                onPressed: () => _pickTime(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) onDateChanged(picked);
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(context: context, initialTime: time);
    if (picked != null) onTimeChanged(picked);
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
