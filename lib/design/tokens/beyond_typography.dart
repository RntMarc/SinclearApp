import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'beyond_tokens.dart';

/// Typographic styles for the catalog. Chivo is the brand typeface (matches the
/// existing DESIGN.md). Styles resolve their color from the active
/// [BeyondColors] so text always respects the current mode.
class BeyondTypography {
  final TextStyle display;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle headline;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle labelSmall;

  const BeyondTypography({
    required this.display,
    required this.titleLarge,
    required this.titleMedium,
    required this.headline,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.label,
    required this.labelSmall,
  });

  factory BeyondTypography.forColors(BeyondColors c) => BeyondTypography(
        display: GoogleFonts.chivo(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: c.onSurface,
          height: 1.1,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.chivo(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: c.onSurface,
          height: 1.15,
        ),
        titleMedium: GoogleFonts.chivo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: c.onSurface,
          height: 1.2,
        ),
        headline: GoogleFonts.chivo(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: c.onSurface,
          height: 1.25,
        ),
        bodyLarge: GoogleFonts.chivo(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: c.onSurface,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.chivo(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: c.onSurfaceVariant,
          height: 1.45,
        ),
        bodySmall: GoogleFonts.chivo(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: c.onSurfaceMuted,
          height: 1.4,
        ),
        label: GoogleFonts.chivo(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: c.onSurface,
          letterSpacing: 0.2,
        ),
        labelSmall: GoogleFonts.chivo(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      );

  /// A [TextTheme] carrying the same styles so un-migrated Material widgets
  /// (and `Theme.of(context).textTheme`) stay consistent during rollout.
  TextTheme toMaterialTextTheme() => TextTheme(
        displayLarge: display,
        displayMedium: display,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        headlineSmall: headline,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: label,
        labelSmall: labelSmall,
      );
}
