import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Termin bearbeiten' : 'Neuer Termin',
               style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _DateTimePicker(
              label: 'Beginn',
              date: _startDate,
              time: _startTime,
              onDateChanged: (d) => setState(() => _startDate = d),
              onTimeChanged: (t) => setState(() => _startTime = t),
            ),
            const SizedBox(height: 12),
            _DateTimePicker(
              label: 'Ende',
              date: _endDate,
              time: _endTime,
              onDateChanged: (d) => setState(() => _endDate = d),
              onTimeChanged: (t) => setState(() => _endTime = t),
            ),
            const SizedBox(height: 16),
            const Text('Sichtbarkeit'),
            const SizedBox(height: 4),
            _VisibilitySelector(
              value: _visibility,
              onChanged: (v) => setState(() => _visibility = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(_isEditing ? 'Speichern' : 'Erstellen'),
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
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: OutlinedButton.icon(
            onPressed: () => _pickDate(context),
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(DateFormat('dd.MM.yyyy').format(date)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () => _pickTime(context),
            icon: const Icon(Icons.access_time_rounded, size: 18),
            label: Text(time.format(context)),
          ),
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
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          label: Text('Privat'),
          icon: Icon(Icons.lock_rounded),
        ),
        ButtonSegment(
          value: 1,
          label: Text('Öffentlich'),
          icon: Icon(Icons.public_rounded),
        ),
        ButtonSegment(
          value: 2,
          label: Text('Freunde'),
          icon: Icon(Icons.people_rounded),
        ),
      ],
      selected: {value},
      onSelectionChanged: (v) => onChanged(v.first),
    );
  }
}
