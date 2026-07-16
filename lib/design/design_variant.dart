/// The three selectable design directions shown in the Design Showcase.
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
}

extension DesignVariantX on DesignVariant {
  /// Human readable name used in the showcase switcher and docs.
  String get label {
    switch (this) {
      case DesignVariant.materiaPop:
        return 'Materia Pop';
      case DesignVariant.auroraGlass:
        return 'Aurora Glass';
      case DesignVariant.liquidPulse:
        return 'Liquid Pulse';
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
    }
  }
}
