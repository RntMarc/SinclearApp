/// The selectable design directions shown in the Design Showcase.
///
/// Each variant resolves to a full [DesignTokens] set (light + dark) via
/// [AppDesign.resolve]. The active variant is held in memory by [DesignScope]
/// and can be switched at runtime from the showcase screen.
enum DesignVariant {
  /// Playful, squircle shapes, springy tap feedback, pastel gradients.
  materiaPop,

  /// Airy frosted-glass surfaces with soft mesh gradients and blur.
  auroraGlass,

  /// Dark, Spotify-like, neon gradient glows and pill shapes.
  liquidPulse,

  /// Warm, golden-hour feel: amber primary, rich gradients, luxurious.
  solstice,

  /// User-defined accent color. The full palette is derived from a single
  /// color chosen by the user.
  custom,
}

extension DesignVariantX on DesignVariant {
  /// Human readable name used in docs and the showcase.
  String get label {
    switch (this) {
      case DesignVariant.materiaPop:
        return 'Materia Pop';
      case DesignVariant.auroraGlass:
        return 'Aurora Glass';
      case DesignVariant.liquidPulse:
        return 'Liquid Pulse';
      case DesignVariant.solstice:
        return 'Solstice';
      case DesignVariant.custom:
        return 'Eigene Farbe';
    }
  }

  /// Short label for the segmented switch where space is limited.
  String get shortLabel {
    switch (this) {
      case DesignVariant.materiaPop:
        return 'Pop';
      case DesignVariant.auroraGlass:
        return 'Aurora';
      case DesignVariant.liquidPulse:
        return 'Pulse';
      case DesignVariant.solstice:
        return 'Gold';
      case DesignVariant.custom:
        return 'Farbe';
    }
  }

  /// Short tagline describing the character of the design.
  String get tagline {
    switch (this) {
      case DesignVariant.materiaPop:
        return 'Verspielt · Squircle · federnd';
      case DesignVariant.auroraGlass:
        return 'Luftig · Glas · weiche Meshes';
      case DesignVariant.liquidPulse:
        return 'Dunkel · Neon · Glow';
      case DesignVariant.solstice:
        return 'Warm · Gold · glänzend';
      case DesignVariant.custom:
        return 'Deine Farbe · dein Stil';
    }
  }
}
