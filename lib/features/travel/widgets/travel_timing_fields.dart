import 'package:flutter/material.dart';

import '../../../core/widgets/time_zone_picker.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_date_time_field.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_chip.dart';

/// Zeitzonenbewusste Timing-Eingabe einer Reise/eines Events.
///
/// Bündelt `allDay`, `timezone` und die passenden Zeitfelder (ganztägig:
/// zivile Tage; getaktet: Wandzeiten). Der Wert wird bei jeder Änderung über
/// [onChanged] gemeldet; die Wandzeiten werden vom Service später in Instants
/// umgerechnet (siehe AGENTS.md Date/Time).
class TravelTimingInput {
  final bool allDay;
  final String timezone;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? startAt;
  final DateTime? endAt;

  const TravelTimingInput({
    required this.allDay,
    required this.timezone,
    this.startDate,
    this.endDate,
    this.startAt,
    this.endAt,
  });
}

class TravelTimingFields extends StatefulWidget {
  const TravelTimingFields({
    required this.initial,
    required this.onChanged,
    super.key,
  });

  final TravelTimingInput initial;
  final ValueChanged<TravelTimingInput> onChanged;

  @override
  State<TravelTimingFields> createState() => _TravelTimingFieldsState();
}

class _TravelTimingFieldsState extends State<TravelTimingFields> {
  late bool _allDay;
  late String _timezone;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _startAt;
  DateTime? _endAt;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _allDay = i.allDay;
    _timezone = i.timezone;
    _startDate = i.startDate;
    _endDate = i.endDate;
    _startAt = i.startAt;
    _endAt = i.endAt;
  }

  void _emit() {
    widget.onChanged(
      TravelTimingInput(
        allDay: _allDay,
        timezone: _timezone,
        startDate: _startDate,
        endDate: _endDate,
        startAt: _startAt,
        endAt: _endAt,
      ),
    );
  }

  void _setAllDay(bool value) {
    setState(() => _allDay = value);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(tokens, 'Zeitraum'),
        SizedBox(height: tokens.spaceSm),
        Row(
          children: [
            DesignChip(
              label: 'Ganztägig',
              selected: _allDay,
              onTap: () => _setAllDay(true),
            ),
            SizedBox(width: tokens.spaceSm),
            DesignChip(
              label: 'Mit Uhrzeit',
              selected: !_allDay,
              onTap: () => _setAllDay(false),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceMd),
        _label(tokens, 'Zeitzone'),
        SizedBox(height: tokens.spaceSm),
        TimeZonePicker(
          value: _timezone,
          onChanged: (zone) {
            setState(() => _timezone = zone);
            _emit();
          },
        ),
        SizedBox(height: tokens.spaceMd),
        _label(tokens, 'Beginn'),
        SizedBox(height: tokens.spaceSm),
        DesignDateTimeField(
          hint: 'Beginn',
          showTime: !_allDay,
          value: _allDay ? _startDate : _startAt,
          onChanged: (value) {
            setState(() {
              if (_allDay) {
                _startDate = value;
              } else {
                _startAt = value;
              }
            });
            _emit();
          },
        ),
        SizedBox(height: tokens.spaceMd),
        _label(tokens, 'Ende'),
        SizedBox(height: tokens.spaceSm),
        DesignDateTimeField(
          hint: 'Ende',
          showTime: !_allDay,
          value: _allDay ? _endDate : _endAt,
          onChanged: (value) {
            setState(() {
              if (_allDay) {
                _endDate = value;
              } else {
                _endAt = value;
              }
            });
            _emit();
          },
        ),
      ],
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
