import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../models/game_models.dart';

/// Ergebnis-Badge eines Matches (Text + Farbe, nie nur Farbe).
class GameResultBadge extends StatelessWidget {
  const GameResultBadge({required this.outcome, super.key});

  final MatchOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final (label, color) = switch (outcome) {
      MatchOutcome.win => ('Sieg', tokens.success),
      MatchOutcome.loss => ('Niederlage', tokens.danger),
      MatchOutcome.penalized => ('Penalty', tokens.warning),
      MatchOutcome.notScored => ('Nicht gewertet', tokens.surfaceVariant),
      MatchOutcome.unknown => ('–', tokens.surfaceVariant),
    };
    return DesignBadge(label: label, color: color);
  }
}
