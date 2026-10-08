import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_badge.dart';
import '../primitives/design_card.dart';
import '../primitives/press_scale.dart';

/// Status einer Planungsphase im Fortschritt.
///
/// Modellfrei: Feature-Modelle werden von der Aufruferseite auf diese Werte
/// abgebildet (Adapter). Status wird immer über Icon **und** Text vermittelt,
/// nie allein über Farbe.
enum DesignPlanPhaseStatus {
  pending('Ausstehend', Icons.radio_button_unchecked_rounded),
  inProgress('Begonnen', Icons.pending_rounded),
  completed('Abgeschlossen', Icons.check_circle_rounded),
  skipped('Übersprungen', Icons.remove_circle_outline_rounded);

  const DesignPlanPhaseStatus(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Eine Phase des Fortschritts (modellfrei).
class DesignPlanPhase {
  const DesignPlanPhase({
    required this.label,
    required this.status,
    this.onTap,
  });

  final String label;
  final DesignPlanPhaseStatus status;

  /// Optionale Tap-Aktion; macht die Zeile antippbar (z. B. Statuswechsel).
  final VoidCallback? onTap;
}

/// Fortschrittsanzeige der Planungsphasen.
///
/// Baut ausschließlich auf `DesignCard` + `DesignText` + `DesignBadge` und den
/// aktiven `DesignTokens` auf. Pro Phase werden Icon, Bezeichnung und
/// Status-Text gezeigt, damit der Zustand nicht allein über Farbe erkennbar
/// ist (Barrierefreiheit).
class DesignPlanPhaseProgress extends StatelessWidget {
  const DesignPlanPhaseProgress({required this.phases, super.key});

  final List<DesignPlanPhase> phases;

  @override
  Widget build(BuildContext context) {
    return DesignCard.list(
      children: <Widget>[for (final phase in phases) _PhaseRow(phase: phase)],
    );
  }
}

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({required this.phase});

  final DesignPlanPhase phase;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final row = Row(
      children: <Widget>[
        Icon(phase.status.icon, color: _color(tokens), size: 20),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: DesignText(
            phase.label,
            style: DesignTextStyle.body,
            color: tokens.textHigh,
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        DesignBadge(label: phase.status.label, color: _color(tokens)),
        if (phase.onTap != null)
          Padding(
            padding: EdgeInsets.only(left: tokens.spaceSm),
            child: Icon(Icons.chevron_right_rounded, color: tokens.textLow),
          ),
      ],
    );
    if (phase.onTap == null) return row;
    return PressScale(onTap: phase.onTap, child: row);
  }

  Color _color(DesignTokens tokens) => switch (phase.status) {
    DesignPlanPhaseStatus.pending => tokens.textLow,
    DesignPlanPhaseStatus.inProgress => tokens.warning,
    DesignPlanPhaseStatus.completed => tokens.success,
    DesignPlanPhaseStatus.skipped => tokens.danger,
  };
}
