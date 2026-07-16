import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_glass.dart';

/// Spacer height used inside the sheet (kept here to avoid a magic number).
const double _sheetSpacer = 12;

/// Shows a design-conformant modal bottom sheet. The sheet surface uses the
/// active design's glass or solid treatment.
Future<T?> showDesignSheet<T>({
  required BuildContext context,
  required Widget child,
  bool useGlass = true,
}) {
  final tokens = DesignTheme.of(context);
  final sheet = Container(
    padding: EdgeInsets.fromLTRB(
      tokens.spaceLg,
      tokens.spaceMd,
      tokens.spaceLg,
      tokens.spaceXl,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: tokens.textLow.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: _sheetSpacer),
        child,
      ],
    ),
  );

  if (useGlass && tokens.useGlass) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DesignGlass(
        radius: tokens.radiusXl,
        padding: EdgeInsets.zero,
        child: sheet,
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusXl),
        ),
        boxShadow: tokens.surfaceShadow,
      ),
      child: sheet,
    ),
  );
}
