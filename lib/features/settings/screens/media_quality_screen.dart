import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/media_quality_preference.dart';

/// Auswahl der Bildqualität für Netzwerk-Medien.
class MediaQualityScreen extends StatelessWidget {
  const MediaQualityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final mediaQuality = AppScope.of(context).mediaQuality;

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'Bildqualität',
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
                      'Bilder & Medien',
                      style: DesignTextStyle.label,
                      color: tokens.primary,
                    ),
                  ),
                  DesignCard.list(
                    children: [
                      for (final quality in MediaQuality.values)
                        DesignListTile(
                          leading: Icon(quality.icon, color: tokens.textHigh),
                          title: quality.label,
                          subtitle: quality.description,
                          trailing: ListenableBuilder(
                            listenable: mediaQuality,
                            builder: (context, _) => Icon(
                              mediaQuality.value == quality
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: mediaQuality.value == quality
                                  ? tokens.primary
                                  : tokens.textLow,
                            ),
                          ),
                          onTap: () => mediaQuality.value = quality,
                        ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceMd),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
                    child: DesignText(
                      'Bei schlechter Verbindung zeigt „Automatisch" Bilder als '
                      'Vorschaubild; einzelne Bilder lassen sich jederzeit in '
                      'voller Qualität laden. „Datensparmodus" spart dauerhaft '
                      'Datenvolumen.',
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
