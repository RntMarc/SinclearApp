import 'package:flutter/cupertino.dart';
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
  late int _startHour;
  late int _startMinute;
  late DateTime _endDate;
  late int _endHour;
  late int _endMinute;
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
    _startHour = event?.startTime.hour ?? now.hour;
    _startMinute = event?.startTime.minute ?? now.minute;
    _endDate = event?.endTime ?? now.add(const Duration(hours: 1));
    _endHour = event?.endTime.hour ?? now.add(const Duration(hours: 1)).hour;
    _endMinute = event?.endTime.minute ?? now.add(const Duration(hours: 1)).minute;
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
    final theme = CupertinoTheme.of(context);
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
                  color: CupertinoColors.systemGrey3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Termin bearbeiten' : 'Neuer Termin',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.textStyle.color,
              ),
            ),
            const SizedBox(height: 20),
            CupertinoTextField(
              controller: _titleController,
              placeholder: 'Titel *',
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _descriptionController,
              placeholder: 'Beschreibung',
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _DateTimePicker(
              label: 'Beginn',
              date: _startDate,
              hour: _startHour,
              minute: _startMinute,
              onDateChanged: (d) => setState(() => _startDate = d),
              onTimeChanged: (h, m) => setState(() {
                _startHour = h;
                _startMinute = m;
              }),
            ),
            const SizedBox(height: 12),
            _DateTimePicker(
              label: 'Ende',
              date: _endDate,
              hour: _endHour,
              minute: _endMinute,
              onDateChanged: (d) => setState(() => _endDate = d),
              onTimeChanged: (h, m) => setState(() {
                _endHour = h;
                _endMinute = m;
              }),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sichtbarkeit',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            _VisibilitySelector(
              value: _visibility,
              onChanged: (v) => setState(() => _visibility = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: _submit,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
      _startHour,
      _startMinute,
    );
    final end = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endHour,
      _endMinute,
    );

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (_) => const CupertinoAlertDialog(
          content: Text('Das Ende muss nach dem Beginn liegen.'),
        ),
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
  final int hour;
  final int minute;
  final ValueChanged<DateTime> onDateChanged;
  final void Function(int hour, int minute) onTimeChanged;

  const _DateTimePicker({
    required this.label,
    required this.date,
    required this.hour,
    required this.minute,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: CupertinoColors.systemGrey6,
            onPressed: () => _pickDate(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.calendar, size: 16),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd.MM.yyyy').format(date),
                  style: TextStyle(
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: CupertinoColors.systemGrey6,
            onPressed: () => _pickTime(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.clock, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fertig'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: date,
                minimumYear: 2020,
                maximumYear: 2035,
                onDateTimeChanged: onDateChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fertig'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoTimerPicker(
                initialTimerDuration: Duration(hours: hour, minutes: minute),
                onTimerDurationChanged: (duration) {
                  onTimeChanged(duration.inHours, duration.inMinutes % 60);
                },
              ),
            ),
          ],
        ),
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
    return CupertinoSegmentedControl<int>(
      children: const {
        0: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.lock_fill, size: 16),
              SizedBox(width: 6),
              Text('Privat'),
            ],
          ),
        ),
        1: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.globe, size: 16),
              SizedBox(width: 6),
              Text('Offentlich'),
            ],
          ),
        ),
        2: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.person_2_fill, size: 16),
              SizedBox(width: 6),
              Text('Freunde'),
            ],
          ),
        ),
      },
      groupValue: value,
      onValueChanged: (v) => onChanged(v),
    );
  }
}
