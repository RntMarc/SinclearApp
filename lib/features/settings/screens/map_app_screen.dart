import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../features/settings/models/map_app_preference.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_card.dart';

class MapAppScreen extends StatelessWidget {
  const MapAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final mapApp = AppScope.of(context).mapApp;

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'Karten-App',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spaceLg,
                      tokens.spaceMd,
                      tokens.spaceLg,
                      tokens.spaceXs,
                    ),
                    child: DesignText(
                      'Bevorzugte Karten-App',
                      style: DesignTextStyle.label,
                      color: tokens.primary,
                    ),
                  ),
                  DesignCard.list(
                    children: [
                      for (final app in MapApp.values)
                        DesignListTile(
                          leading: Icon(app.icon, color: tokens.textHigh),
                          title: app.label,
                          subtitle: app.description,
                          trailing: ListenableBuilder(
                            listenable: mapApp,
                            builder: (context, _) => Icon(
                              mapApp.value == app
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: mapApp.value == app
                                  ? tokens.primary
                                  : tokens.textLow,
                            ),
                          ),
                          onTap: () => mapApp.value = app,
                        ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceMd),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
                    child: DesignText(
                      'Bei „Jedes Mal fragen" wird vor jedem Öffnen eine Auswahl angezeigt. '
                      'Bei den anderen Optionen wird direkt die gewählte App geöffnet.',
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
