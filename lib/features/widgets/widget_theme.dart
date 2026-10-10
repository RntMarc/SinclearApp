import 'package:flutter/material.dart' show Brightness, Color;

import '../../design/design_variant.dart';
import '../../design/theme/app_design.dart';
import '../../design/tokens/design_tokens.dart';

/// Material-3-Theme für die Widgets: Look & Feel (Typografie, Radien,
/// Shapes) kommt von Glance/Material 3, **nur die Farben** stammen aus den
/// [DesignTokens] der aktiven App-Design-Variante.
///
/// Liefert beide Helligkeiten; Glance wählt anhand des System-Darkmode die
/// passende. So folgt das Widget automatisch der gewählten Variante und dem
/// Hell/Dunkel-Modus, ohne dass Effekte (Glas/Grain/Glow) oder die
/// App-Schrift (Chivo) übernommen werden.
class WidgetTheme {
  const WidgetTheme({required this.light, required this.dark});

  final Map<String, String> light;
  final Map<String, String> dark;

  /// Baut das Theme für [variant] (+ optional [customAccent] für die
  /// „Eigene Farbe"-Variante).
  static WidgetTheme fromVariant(
    DesignVariant variant, {
    Color? customAccent,
  }) {
    return WidgetTheme(
      light: _colors(
        AppDesign.resolve(variant, Brightness.light, customAccent: customAccent),
      ),
      dark: _colors(
        AppDesign.resolve(variant, Brightness.dark, customAccent: customAccent),
      ),
    );
  }

  /// Übersetzt die relevanten Token-Farben in die Material-3-Rollen.
  static Map<String, String> _colors(DesignTokens t) => <String, String>{
    'primary': _hex(t.primary),
    'onPrimary': _hex(t.onPrimary),
    'secondary': _hex(t.secondary),
    'onSecondary': _hex(t.onSecondary),
    'tertiary': _hex(t.accentA),
    'surface': _hex(t.surface),
    'surfaceVariant': _hex(t.surfaceVariant),
    'onSurface': _hex(t.textHigh),
    'onSurfaceVariant': _hex(t.textLow),
    'background': _hex(t.background),
    'onBackground': _hex(t.textHigh),
    'error': _hex(t.danger),
    'outline': _hex(t.border),
  };

  static String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'light': light,
    'dark': dark,
  };
}
