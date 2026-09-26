import 'package:flutter/material.dart';
import '../../design/theme/design_theme.dart';
import '../../design/widgets/composite/design_bottom_sheet.dart';
import '../../design/widgets/foundation/design_text.dart';
import '../di/app_scope.dart';

/// Oeffnet die durchsuchbare Zeitzonen-Auswahl und liefert die gewaehlte Zone
/// oder null bei Abbruch.
Future<String?> showTimeZoneSheet({
  required BuildContext context,
  required String value,
  String title = 'Zeitzone',
}) async {
  final zones = AppScope.of(context).timeZones.availableZones;
  return showDesignSheet<String>(
    context: context,
    child: _TimeZoneSheet(zones: zones, value: value, title: title),
  );
}

/// Auswahlfeld fuer IANA-Zeitzonen mit Suche.
///
/// Zeigt den aktuellen Wert im Stil der Design-Formularfelder und oeffnet
/// eine durchsuchbare Liste aller verfuegbaren Zonen.
class TimeZonePicker extends StatelessWidget {
  const TimeZonePicker({
    required this.value,
    required this.onChanged,
    this.hint = 'Zeitzone',
    super.key,
  });

  /// Aktuell gewaehlte IANA-Zeitzone.
  final String value;

  /// Wird beim Auswaehlen einer Zone aufgerufen.
  final ValueChanged<String> onChanged;

  final String hint;

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showTimeZoneSheet(
      context: context,
      value: value,
      title: hint,
    );
    if (picked != null && picked != value) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
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
            Icon(Icons.public_rounded, color: tokens.textLow, size: 20),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: DesignText(
                value.isEmpty ? hint : value,
                style: DesignTextStyle.body,
                color: value.isEmpty ? tokens.textLow : tokens.textHigh,
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

class _TimeZoneSheet extends StatefulWidget {
  const _TimeZoneSheet({
    required this.zones,
    required this.value,
    required this.title,
  });

  final List<String> zones;
  final String value;
  final String title;

  @override
  State<_TimeZoneSheet> createState() => _TimeZoneSheetState();
}

class _TimeZoneSheetState extends State<_TimeZoneSheet> {
  String _query = '';

  List<String> get _filtered {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.zones;
    return widget.zones
        .where((zone) => zone.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final zones = _filtered;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesignText(
            widget.title,
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          TextField(
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Zeitzone suchen...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMd),
              ),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          SizedBox(height: tokens.spaceMd),
          SizedBox(
            height: 360,
            child: ListView.builder(
              itemCount: zones.length,
              itemBuilder: (context, index) {
                final zone = zones[index];
                final selected = zone == widget.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceSm,
                  ),
                  title: Text(
                    zone,
                    style: TextStyle(
                      color: selected ? tokens.primary : tokens.textHigh,
                    ),
                  ),
                  trailing: selected
                      ? Icon(Icons.check_rounded, color: tokens.primary)
                      : null,
                  onTap: () => Navigator.pop(context, zone),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
