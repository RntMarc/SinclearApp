import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_chip.dart';
import '../primitives/design_card.dart';

/// Verfügbarkeit eines Teilnehmers für einen Terminvorschlag.
enum DesignAvailability {
  yes('Ja'),
  maybe('Vielleicht'),
  no('Nein');

  const DesignAvailability(this.label);

  final String label;
}

/// Model-freie Zeile der Verfügbarkeitsmatrix: Terminvorschlag mit eigener
/// Auswahl und (optional) aggregierten Stimmen.
class DesignAvailabilityOption {
  const DesignAvailabilityOption({
    required this.id,
    required this.label,
    this.selected,
    this.counts = const {},
    this.isCounterProposal = false,
  });

  final String id;
  final String label;
  final DesignAvailability? selected;
  final Map<DesignAvailability, int> counts;
  final bool isCounterProposal;
}

/// Doodle-artige Verfügbarkeitsmatrix (Optionen × Ja/Vielleicht/Nein).
///
/// Baut auf [DesignCard] + [DesignChip] auf. Im editierbaren Modus wählt ein
/// Tap die eigene Verfügbarkeit je Option (`onChanged` mit `null` entfernt die
/// Stimme); im `readOnly`-Modus werden die aggregierten Stimmen angezeigt.
class DesignAvailabilityMatrix extends StatelessWidget {
  const DesignAvailabilityMatrix({
    required this.options,
    this.onChanged,
    this.readOnly = false,
    super.key,
  });

  final List<DesignAvailabilityOption> options;
  final void Function(String optionId, DesignAvailability? value)? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < options.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: tokens.spaceSm),
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DesignText(
                        options[i].label,
                        style: DesignTextStyle.body,
                        color: tokens.textHigh,
                      ),
                    ),
                    if (options[i].isCounterProposal)
                      const DesignChip(label: 'Gegenvorschlag'),
                  ],
                ),
                SizedBox(height: tokens.spaceSm),
                if (readOnly)
                  _counts(context, options[i])
                else
                  _chips(context, options[i]),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _chips(BuildContext context, DesignAvailabilityOption option) {
    final tokens = DesignTheme.of(context);
    return Wrap(
      spacing: tokens.spaceSm,
      runSpacing: tokens.spaceSm,
      children: <Widget>[
        for (final availability in DesignAvailability.values)
          DesignChip(
            label: availability.label,
            selected: option.selected == availability,
            onTap: onChanged == null
                ? null
                : () => onChanged!(
                    option.id,
                    option.selected == availability ? null : availability,
                  ),
          ),
      ],
    );
  }

  Widget _counts(BuildContext context, DesignAvailabilityOption option) {
    final tokens = DesignTheme.of(context);
    final parts = <String>[
      for (final availability in DesignAvailability.values)
        if ((option.counts[availability] ?? 0) > 0)
          '${option.counts[availability]} ${availability.label}',
    ];
    return DesignText(
      parts.isEmpty ? 'Noch keine Rückmeldungen' : parts.join(' · '),
      style: DesignTextStyle.label,
      color: tokens.textLow,
    );
  }
}
