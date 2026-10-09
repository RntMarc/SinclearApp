import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/travel_models.dart';

/// Zeigt eine Auswahl von Unterkünften aus dem Reise-/Katalogbestand.
///
/// Rückgabe:
/// * `null` – abgebrochen
/// * leerer String – Zuordnung aufheben (nur bei [allowNone])
/// * sonst die ID der gewählten Unterkunft
///
/// Mit [description] erscheint eine kurze Erklärzeile unter dem Titel; mit
/// [searchable] lässt sich die Liste client-seitig nach Name/Adresse filtern.
Future<String?> showAccommodationPicker(
  BuildContext context, {
  required List<TravelAccommodation> options,
  String? selectedId,
  bool allowNone = false,
  String title = 'Unterkunft wählen',
  String? description,
  bool searchable = false,
}) {
  return showDesignSheet<String>(
    context: context,
    child: _AccommodationPicker(
      options: options,
      selectedId: selectedId,
      allowNone: allowNone,
      title: title,
      description: description,
      searchable: searchable,
    ),
  );
}

class _AccommodationPicker extends StatefulWidget {
  const _AccommodationPicker({
    required this.options,
    required this.selectedId,
    required this.allowNone,
    required this.title,
    required this.description,
    required this.searchable,
  });

  final List<TravelAccommodation> options;
  final String? selectedId;
  final bool allowNone;
  final String title;
  final String? description;
  final bool searchable;

  @override
  State<_AccommodationPicker> createState() => _AccommodationPickerState();
}

class _AccommodationPickerState extends State<_AccommodationPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Nach Name/Adresse gefilterte Optionen (nur bei [searchable] aktiv).
  List<TravelAccommodation> get _visible {
    if (!widget.searchable) return widget.options;
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return widget.options
        .where(
          (a) =>
              a.name.toLowerCase().contains(query) ||
              (a.address ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final visible = _visible;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          widget.title,
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        if (widget.description != null) ...[
          SizedBox(height: tokens.spaceXs),
          DesignText(
            widget.description!,
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
        ],
        SizedBox(height: tokens.spaceMd),
        if (widget.searchable) ...[
          DesignTextField(
            hint: 'Unterkunft suchen',
            controller: _search,
            prefixIcon: Icons.search_rounded,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: tokens.spaceMd),
        ],
        if (widget.allowNone)
          DesignListTile(
            leading: Icon(Icons.block_rounded, color: tokens.textLow, size: 20),
            title: 'Keine Unterkunft',
            trailing: widget.selectedId == null
                ? Icon(Icons.check_rounded, color: tokens.primary, size: 18)
                : null,
            padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
            onTap: () => Navigator.pop(context, ''),
          ),
        if (visible.isEmpty)
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
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final accommodation = visible[index];
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
                  trailing: accommodation.id == widget.selectedId
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
