import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../models/travel_models.dart';

/// Zeigt eine Auswahl von Unterkünften aus dem Reise-/Katalogbestand.
///
/// Rückgabe:
/// * `null` – abgebrochen
/// * leerer String – Zuordnung aufheben (nur bei [allowNone])
/// * sonst die ID der gewählten Unterkunft
Future<String?> showAccommodationPicker(
  BuildContext context, {
  required List<TravelAccommodation> options,
  String? selectedId,
  bool allowNone = false,
  String title = 'Unterkunft wählen',
}) {
  return showDesignSheet<String>(
    context: context,
    child: _AccommodationPicker(
      options: options,
      selectedId: selectedId,
      allowNone: allowNone,
      title: title,
    ),
  );
}

class _AccommodationPicker extends StatelessWidget {
  final List<TravelAccommodation> options;
  final String? selectedId;
  final bool allowNone;
  final String title;

  const _AccommodationPicker({
    required this.options,
    required this.selectedId,
    required this.allowNone,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          title,
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        if (allowNone)
          DesignListTile(
            leading: Icon(Icons.block_rounded, color: tokens.textLow, size: 20),
            title: 'Keine Unterkunft',
            trailing: selectedId == null
                ? Icon(Icons.check_rounded, color: tokens.primary, size: 18)
                : null,
            padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
            onTap: () => Navigator.pop(context, ''),
          ),
        if (options.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
            child: DesignText(
              'Keine Unterkünfte verfügbar.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final accommodation = options[index];
                return DesignListTile(
                  leading: Icon(
                    accommodation.ishotel == 1
                        ? Icons.hotel_rounded
                        : Icons.home_rounded,
                    color: tokens.textHigh,
                    size: 20,
                  ),
                  title: accommodation.name,
                  subtitle: accommodation.address,
                  trailing: accommodation.id == selectedId
                      ? Icon(
                          Icons.check_rounded,
                          color: tokens.primary,
                          size: 18,
                        )
                      : null,
                  padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
                  onTap: () => Navigator.pop(context, accommodation.id),
                );
              },
            ),
          ),
      ],
    );
  }
}
