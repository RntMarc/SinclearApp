import 'package:flutter/material.dart';
import '../../design_variant.dart';
import '../../theme/app_design.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/press_scale.dart';

/// The design switcher shown at the top of the showcase. It re-styles itself
/// to match the active design and updates the in-memory [DesignScope] notifier
/// when a segment is tapped, which instantly re-themes every catalog widget.
class DesignSegmentedSwitch extends StatelessWidget {
  const DesignSegmentedSwitch({super.key});


  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final active = DesignScope.variantOf(context);
    final notifier = DesignScope.notifierOf(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: AppDesign.all.map((variant) {
          final isActive = variant == active;
          final segment = Expanded(
            child: PressScale(
              onTap: () => notifier.value = variant,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
                decoration: BoxDecoration(
                  color: isActive ? tokens.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                  boxShadow: isActive ? tokens.glowShadow : null,
                ),
                alignment: Alignment.center,
                child: DesignText(
                  variant.label,
                  style: DesignTextStyle.label,
                  color: isActive ? tokens.textOnPrimary : tokens.textLow,
                ),
              ),
            ),
          );
          return segment;
        }).toList(),
      ),
    );
  }
}
