import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Read-only Datum- bzw. Datum+Uhrzeit-Auswahlfeld im Design-Token-Stil.
///
/// Ersetzt Material-`showDatePicker`/`showTimePicker`-Trigger in Formularen
/// und sieht wie ein [DesignTextField] aus (Border, Radius, Hintergrund und
/// Fokus-Glow folgen den aktiven [DesignTokens]). Mit [showTime] = false wird
/// nur ein Datum gewählt, sonst Datum und Uhrzeit.
class DesignDateTimeField extends StatelessWidget {
  const DesignDateTimeField({
    required this.value,
    required this.onChanged,
    this.hint,
    this.showTime = true,
    this.prefixIcon = Icons.event_rounded,
    super.key,
  });

  /// Aktuell gewählter Zeitpunkt (Wandzeit), `null` wenn nichts gewählt.
  final DateTime? value;

  /// Wird beim Auswählen mit dem neuen Zeitpunkt aufgerufen.
  final ValueChanged<DateTime> onChanged;

  /// Platzhaltertext, solange kein Wert gewählt ist.
  final String? hint;

  /// Ob zusätzlich zur Uhrzeit ein Datum gewählt wird.
  final bool showTime;

  final IconData prefixIcon;

  Future<void> _openPicker(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
    );
    if (pickedDate == null) return;
    if (!context.mounted) return;

    var result = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      initial.hour,
      initial.minute,
    );

    if (showTime) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (pickedTime == null) return;
      result = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }

    onChanged(result);
  }

  static String _format(DateTime value, bool showTime) {
    final date =
        '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.'
        '${value.year}';
    if (!showTime) return date;
    final time =
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final label = value != null ? _format(value!, showTime) : null;
    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceSm,
        ),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(
            color: tokens.border.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(prefixIcon, color: tokens.textLow, size: 20),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: DesignText(
                label ?? hint ?? '',
                style: DesignTextStyle.body,
                color: label != null ? tokens.textHigh : tokens.textLow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            Icon(Icons.expand_more_rounded, color: tokens.textLow, size: 20),
          ],
        ),
      ),
    );
  }
}
