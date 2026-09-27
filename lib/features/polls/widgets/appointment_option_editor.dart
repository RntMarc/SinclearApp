import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_question_field.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/poll_models.dart';

/// Editor für einen Terminvorschlag (ganztägig oder getaktet).
///
/// Meldet über [onChanged] den fertigen [PollOptionInput] — `null`, solange
/// kein Beginn gewählt ist. Wird im Erstell-Wizard und beim Gegenvorschlag
/// wiederverwendet. Eine freie Bezeichnung gibt es bewusst nicht mehr; die
/// Option wird über ihren Beginn-/Endzeitpunkt identifiziert.
class AppointmentOptionEditor extends StatefulWidget {
  const AppointmentOptionEditor({
    required this.timezone,
    required this.onChanged,
    this.onRemove,
    super.key,
  });

  final String timezone;
  final ValueChanged<PollOptionInput?> onChanged;
  final VoidCallback? onRemove;

  @override
  State<AppointmentOptionEditor> createState() =>
      _AppointmentOptionEditorState();
}

class _AppointmentOptionEditorState extends State<AppointmentOptionEditor> {
  bool _allDay = true;
  DateTime? _start;
  DateTime? _end;

  void _emit() {
    final start = _start;
    if (start == null) {
      widget.onChanged(null);
      return;
    }
    final end = _end ?? start;
    widget.onChanged(
      PollOptionInput(
        allDay: _allDay,
        timezone: widget.timezone,
        startAt: _allDay ? null : wallTimeToInstant(start, widget.timezone),
        endAt: _allDay ? null : wallTimeToInstant(end, widget.timezone),
        startDate: _allDay ? start : null,
        endDate: _allDay ? end : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            DesignChip(
              label: 'Ganztägig',
              selected: _allDay,
              onTap: () {
                setState(() => _allDay = true);
                _emit();
              },
            ),
            SizedBox(width: tokens.spaceSm),
            DesignChip(
              label: 'Mit Uhrzeit',
              selected: !_allDay,
              onTap: () {
                setState(() => _allDay = false);
                _emit();
              },
            ),
            const Spacer(),
            if (widget.onRemove != null)
              DesignIconButton(
                icon: Icons.remove_circle_outline_rounded,
                onPressed: widget.onRemove,
              ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        DesignQuestionField(
          spec: DesignQuestionSpec(
            kind: _allDay
                ? DesignQuestionKind.date
                : DesignQuestionKind.datetime,
            title: 'Beginn',
          ),
          value: _start,
          onChanged: (value) {
            setState(() => _start = value is DateTime ? value : null);
            _emit();
          },
        ),
        SizedBox(height: tokens.spaceSm),
        DesignQuestionField(
          spec: DesignQuestionSpec(
            kind: _allDay
                ? DesignQuestionKind.date
                : DesignQuestionKind.datetime,
            title: 'Ende',
          ),
          value: _end,
          onChanged: (value) {
            setState(() => _end = value is DateTime ? value : null);
            _emit();
          },
        ),
      ],
    );
  }
}
