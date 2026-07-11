import 'package:flutter/material.dart';
import '../design_variant.dart';
import '../tokens/aurora_glass_tokens.dart';
import '../tokens/design_tokens.dart';
import '../tokens/liquid_pulse_tokens.dart';
import '../tokens/materia_pop_tokens.dart';

/// Resolves a concrete [DesignTokens] set for a [DesignVariant] and brightness.
///
/// This is the single place that maps the three showcase directions to their
/// token instances, so adding a fourth design only requires a new case here.
class AppDesign {
  AppDesign._();

  static DesignTokens resolve(DesignVariant variant, Brightness brightness) {
    return switch (variant) {
      DesignVariant.materiaPop => MateriaPopTokens(brightness),
      DesignVariant.auroraGlass => AuroraGlassTokens(brightness),
      DesignVariant.liquidPulse => LiquidPulseTokens(brightness),
    };
  }

  /// All variants in display order, used by the showcase switcher.
  static const List<DesignVariant> all = <DesignVariant>[
    DesignVariant.materiaPop,
    DesignVariant.auroraGlass,
    DesignVariant.liquidPulse,
  ];
}
