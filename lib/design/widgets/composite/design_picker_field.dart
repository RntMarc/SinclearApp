import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/press_scale.dart';
import 'design_bottom_sheet.dart';

/// Eine Auswahloption für [DesignPickerField].
class DesignPickerItem {
  const DesignPickerItem({required this.value, required this.label, this.icon});

  final String value;
  final String label;

  /// Optionales Emoji, das vor dem Label angezeigt wird.
  final String? icon;
}

/// Read-only-Auswahlfeld im Design-Token-Stil, das eine [showDesignSheet]-
/// Auswahlliste öffnet.
///
/// Ersetzt Material-`Dropdown`s in Formularen und sorgt dafür, dass jede
/// Auswahl wie ein [DesignTextField] aussieht (Border, Radius, Fokus-Glow
/// folgen den aktiven [DesignTokens]).
class DesignPickerField extends StatelessWidget {
  const DesignPickerField({
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    this.prefixIcon,
    super.key,
  });

  /// Alle auswählbaren Optionen.
  final List<DesignPickerItem> items;

  /// Aktuell gewählter API-Wert (aus [DesignPickerItem.value]).
  final String? value;

  /// Wird beim Auswählen einer Option mit deren Wert aufgerufen.
  final ValueChanged<String> onChanged;

  /// Platzhaltertext, solange keine Auswahl getroffen wurde.
  final String? hint;

  final IconData? prefixIcon;

  String? get _selectedLabel {
    if (value == null) return null;
    for (final item in items) {
      if (item.value == value) return item.label;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    final tokens = DesignTheme.of(context);
    final picked = await showDesignSheet<String>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesignText(
            hint ?? 'Auswählen',
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          ...items.map((item) {
            final selected = item.value == value;
            return PressScale(
              onTap: () => Navigator.pop(context, item.value),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: tokens.spaceMd,
                  horizontal: tokens.spaceXs,
                ),
                child: Row(
                  children: [
                    if (item.icon != null) ...<Widget>[
                      Text(
                        item.icon!,
                        style: const TextStyle(
                          fontSize: 16,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      SizedBox(width: tokens.spaceSm),
                    ],
                    Expanded(
                      child: DesignText(
                        item.label,
                        style: DesignTextStyle.body,
                        color: selected ? tokens.primary : tokens.textHigh,
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: tokens.primary,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
    if (picked != null && picked != value) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final label = _selectedLabel;
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
            if (prefixIcon != null) ...<Widget>[
              Icon(prefixIcon, color: tokens.textLow, size: 20),
              SizedBox(width: tokens.spaceSm),
            ],
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
