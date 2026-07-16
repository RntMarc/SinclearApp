import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
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
        tokens.spaceLg, tokens.spaceLg, tokens.spaceLg, tokens.spaceLg + bottomInset,
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
            DesignTextField(
              hint: 'Titel *',
              controller: _titleController,
            ),
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
        variant: selected ? DesignButtonVariant.filled : DesignButtonVariant.outlined,
        onPressed: () => onChanged(v),
      ),
    );
  }
}
