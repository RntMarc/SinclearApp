import 'package:flutter/material.dart';

/// Raw brand palette. Never reference these directly inside widgets – go
/// through [BeyondTokens] so light/dark resolution stays centralized and the
/// whole app can be re-themed by editing one place.
class BeyondBrand {
  static const Color blue = Color(0xFF0064EA);
  static const Color blueDeep = Color(0xFF003E8F);
  static const Color magenta = Color(0xFFBC0091);
  static const Color magentaSoft = Color(0xFFE23CBE);

  /// Signature brand gradient (blue -> magenta), top-left to bottom-right.
  static const LinearGradient signature = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[blue, magenta],
  );

  static LinearGradient signatureFrom(Alignment begin, Alignment end) =>
      LinearGradient(
        begin: begin,
        end: end,
        colors: const <Color>[blue, magenta],
      );
}

/// Corner radii used across the catalog.
class BeyondRadii {
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double pill;

  const BeyondRadii({
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.pill,
  });

  static const BeyondRadii standard = BeyondRadii(
    sm: 8,
    md: 14,
    lg: 22,
    xl: 32,
    pill: 999,
  );
}

/// Spacing scale (4dp grid).
class BeyondSpacing {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  const BeyondSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
  });

  static const BeyondSpacing standard = BeyondSpacing(
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    xxl: 32,
    xxxl: 48,
  );
}

/// Motion tokens (durations + standard curves).
class BeyondMotion {
  final Duration fast;
  final Duration med;
  final Duration slow;
  final Curve curveStandard;
  final Curve curveEmphasized;

  const BeyondMotion({
    required this.fast,
    required this.med,
    required this.slow,
    required this.curveStandard,
    required this.curveEmphasized,
  });

  static const BeyondMotion standard = BeyondMotion(
    fast: Duration(milliseconds: 150),
    med: Duration(milliseconds: 250),
    slow: Duration(milliseconds: 400),
    curveStandard: Curves.easeOutCubic,
    curveEmphasized: Curves.easeOutExpo,
  );
}

/// Resolved color set for a single brightness.
class BeyondColors {
  final Color surfaceBase;
  final Color surfaceRaised;
  final Color surfaceGlassFill;
  final Color surfaceGlassStroke;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onSurfaceMuted;
  final Color borderSubtle;
  final Color borderStrong;
  final Color brandBlue;
  final Color brandMagenta;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color scrim;

  const BeyondColors({
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceGlassFill,
    required this.surfaceGlassStroke,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onSurfaceMuted,
    required this.borderSubtle,
    required this.borderStrong,
    required this.brandBlue,
    required this.brandMagenta,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.scrim,
  });

  static const BeyondColors dark = BeyondColors(
    surfaceBase: Color(0xFF011219),
    surfaceRaised: Color(0xFF0B1B25),
    surfaceGlassFill: Color(0x1FFFFFFF),
    surfaceGlassStroke: Color(0x33FFFFFF),
    onSurface: Color(0xFFE6E1E5),
    onSurfaceVariant: Color(0xFFAEB8C2),
    onSurfaceMuted: Color(0xFF7C8794),
    borderSubtle: Color(0x1FFFFFFF),
    borderStrong: Color(0x33FFFFFF),
    brandBlue: BeyondBrand.blue,
    brandMagenta: BeyondBrand.magenta,
    success: Color(0xFF3DDC84),
    warning: Color(0xFFFFB020),
    danger: Color(0xFFFF5C7A),
    info: Color(0xFF4DA3FF),
    scrim: Color(0xCC011219),
  );

  static const BeyondColors light = BeyondColors(
    surfaceBase: Color(0xFFF6F8FC),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceGlassFill: Color(0x73FFFFFF),
    surfaceGlassStroke: Color(0xB3FFFFFF),
    onSurface: Color(0xFF0A1622),
    onSurfaceVariant: Color(0xFF5A6573),
    onSurfaceMuted: Color(0xFF8A93A0),
    borderSubtle: Color(0x1A0A1622),
    borderStrong: Color(0x330A1622),
    brandBlue: BeyondBrand.blue,
    brandMagenta: BeyondBrand.magenta,
    success: Color(0xFF1BA75B),
    warning: Color(0xFFB97900),
    danger: Color(0xFFD6324F),
    info: Color(0xFF1E6FD0),
    scrim: Color(0x990A1622),
  );

  Brightness get brightness =>
      surfaceBase.computeLuminance() < 0.5 ? Brightness.dark : Brightness.light;
}

/// Glass effect parameters.
class BeyondGlassTokens {
  final double blurSigma;
  final double fillOpacity;
  final double strokeOpacity;

  const BeyondGlassTokens({
    required this.blurSigma,
    required this.fillOpacity,
    required this.strokeOpacity,
  });

  static const BeyondGlassTokens dark = BeyondGlassTokens(
    blurSigma: 18,
    fillOpacity: 0.12,
    strokeOpacity: 0.20,
  );

  static const BeyondGlassTokens light = BeyondGlassTokens(
    blurSigma: 14,
    fillOpacity: 0.55,
    strokeOpacity: 0.70,
  );
}

/// Glow effect parameters (multi-layer soft shadow in brand color).
class BeyondGlowTokens {
  final Color brandColor;
  final double brandBlur;
  final Color softColor;
  final double softBlur;
  final List<BoxShadow> brandBoxShadow;
  final List<BoxShadow> softBoxShadow;

  const BeyondGlowTokens({
    required this.brandColor,
    required this.brandBlur,
    required this.softColor,
    required this.softBlur,
    required this.brandBoxShadow,
    required this.softBoxShadow,
  });

  static BeyondGlowTokens forColors(BeyondColors c) => BeyondGlowTokens(
        brandColor: c.brandBlue,
        brandBlur: 18,
        softColor: c.brightness == Brightness.dark
            ? Colors.black
            : Colors.black12,
        softBlur: 24,
        brandBoxShadow: <BoxShadow>[
          BoxShadow(
            color: c.brandBlue.withValues(alpha: 0.45),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
        softBoxShadow: <BoxShadow>[
          BoxShadow(
            color: c.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      );
}

/// The full, resolved token set for one brightness.
class BeyondTokens {
  final Brightness brightness;
  final BeyondColors color;
  final BeyondRadii radius;
  final BeyondSpacing spacing;
  final BeyondGlassTokens glass;
  final BeyondGlowTokens glow;
  final BeyondMotion motion;
  final double grainOpacity;

  const BeyondTokens({
    required this.brightness,
    required this.color,
    required this.radius,
    required this.spacing,
    required this.glass,
    required this.glow,
    required this.motion,
    required this.grainOpacity,
  });

  factory BeyondTokens.forBrightness(Brightness brightness) =>
      brightness == Brightness.dark
          ? BeyondTokens.dark()
          : BeyondTokens.light();

  factory BeyondTokens.dark() => BeyondTokens(
        brightness: Brightness.dark,
        color: BeyondColors.dark,
        radius: BeyondRadii.standard,
        spacing: BeyondSpacing.standard,
        glass: BeyondGlassTokens.dark,
        glow: BeyondGlowTokens.forColors(BeyondColors.dark),
        motion: BeyondMotion.standard,
        grainOpacity: 0.012,
      );

  factory BeyondTokens.light() => BeyondTokens(
        brightness: Brightness.light,
        color: BeyondColors.light,
        radius: BeyondRadii.standard,
        spacing: BeyondSpacing.standard,
        glass: BeyondGlassTokens.light,
        glow: BeyondGlowTokens.forColors(BeyondColors.light),
        motion: BeyondMotion.standard,
        grainOpacity: 0.008,
      );
}
