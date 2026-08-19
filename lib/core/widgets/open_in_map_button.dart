import 'package:flutter/material.dart';

import '../../features/settings/models/map_app_preference.dart';
import '../di/app_scope.dart';
import '../utils/map_helper.dart';
import '../../design/theme/design_theme.dart';
import '../../design/widgets/composite/design_bottom_sheet.dart';
import '../../design/widgets/composite/design_list_tile.dart';
import '../../design/widgets/foundation/design_text.dart';
import '../../design/widgets/primitives/press_scale.dart';

/// Small round button that opens [target] in an external map application.
///
/// Position it as the sibling of a map card inside a `Stack`; it places itself
/// in the bottom-right corner of the card. When the user has set a concrete
/// preference, tapping opens that app directly; when it is [MapApp.ask], a
/// bottom-sheet picker is shown first.
class OpenInMapButton extends StatelessWidget {
  final MapTarget target;

  const OpenInMapButton({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Positioned(
      right: 12,
      bottom: 12,
      child: ListenableBuilder(
        listenable: AppScope.of(context).mapApp,
        builder: (context, _) {
          final app = AppScope.of(context).mapApp.value;
          final label = app == MapApp.ask
              ? 'Karte öffnen'
              : 'In ${app.label} öffnen';
          return Semantics(
            button: true,
            label: label,
            child: Tooltip(
              message: label,
              child: PressScale(
                onTap: () => _onTap(context, app),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tokens.primary,
                    shape: BoxShape.circle,
                    boxShadow: tokens.surfaceShadow,
                  ),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    color: tokens.textOnPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onTap(BuildContext context, MapApp app) {
    if (app == MapApp.ask) {
      showMapAppPicker(context: context, target: target);
    } else {
      openMapTarget(app, target);
    }
  }
}

/// Shows a bottom-sheet picker with the three concrete map apps.
Future<void> showMapAppPicker({
  required BuildContext context,
  required MapTarget target,
}) {
  final tokens = DesignTheme.of(context);
  return showDesignSheet(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(
          'Karte öffnen mit…',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        for (final app in [MapApp.osm, MapApp.googleMaps, MapApp.appleMaps])
          DesignListTile(
            leading: Icon(app.icon, color: tokens.textHigh),
            title: app.label,
            subtitle: app.description,
            onTap: () {
              Navigator.pop(context);
              openMapTarget(app, target);
            },
          ),
      ],
    ),
  );
}
