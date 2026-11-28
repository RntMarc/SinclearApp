import 'package:material_ui/material_ui.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Unaufdringlicher Quellennachweis für Karten mit OSM-Kacheln.
///
/// Die OSM-Tile-Policy verlangt den Nachweis in der UI. Der Hinweis liegt
/// nicht-interaktiv über der Karte, damit Gesten ungehindert durchgehen.
class DesignMapAttribution extends StatelessWidget {
  const DesignMapAttribution({
    super.key,
    this.text = '© OpenStreetMap contributors',
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Align(
      alignment: Alignment.bottomRight,
      child: IgnorePointer(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceXs),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(tokens.radiusSm),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceXs,
                vertical: 2,
              ),
              child: DesignText(
                text,
                style: DesignTextStyle.label,
                color: tokens.textLow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
