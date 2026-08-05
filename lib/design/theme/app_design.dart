import 'package:flutter/material.dart';
import '../design_variant.dart';
import '../tokens/aurora_glass_tokens.dart';
import '../tokens/custom_tokens.dart';
import '../tokens/design_tokens.dart';
import '../tokens/liquid_pulse_tokens.dart';
import '../tokens/materia_pop_tokens.dart';
import '../tokens/solstice_tokens.dart';

/// Resolves a concrete [DesignTokens] set for a [DesignVariant] and brightness.
///
/// This is the single place that maps the showcase directions to their
/// token instances, so adding a new design only requires a new case here.
class AppDesign {
  AppDesign._();

  static DesignTokens resolve(
    DesignVariant variant,
    Brightness brightness, {
    Color? customAccent,
  }) {
    return switch (variant) {
      DesignVariant.materiaPop => MateriaPopTokens(brightness),
      DesignVariant.auroraGlass => AuroraGlassTokens(brightness),
      DesignVariant.liquidPulse => LiquidPulseTokens(brightness),
      DesignVariant.solstice => SolsticeTokens(brightness),
      DesignVariant.custom => CustomTokens(
          customAccent ?? const Color(0xFF0064EA),
          brightness,
        ),
    };
  }

  /// All variants in display order, used by the showcase switcher.
  static const List<DesignVariant> all = <DesignVariant>[
    DesignVariant.materiaPop,
    DesignVariant.auroraGlass,
    DesignVariant.liquidPulse,
    DesignVariant.solstice,
    DesignVariant.custom,
  ];
}
