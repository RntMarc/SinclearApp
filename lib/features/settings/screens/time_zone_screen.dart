import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/widgets/time_zone_picker.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';

/// Einstellungen der persoenlichen Zeitzone.
///
/// Die gewaehlte IANA-Zeitzone wird als Nutzerpraeferenz gespeichert und fuer
/// neue Kalender-/Reise-Eintraege sowie als Anzeige-Fallback verwendet. Ohne
/// Auswahl gilt die Geraetezeitzone.
class TimeZoneScreen extends StatefulWidget {
  const TimeZoneScreen({super.key});

  @override
  State<TimeZoneScreen> createState() => _TimeZoneScreenState();
}

class _TimeZoneScreenState extends State<TimeZoneScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    try {
      final prefs = await scope.user.getPreferences();
      scope.timeZones.setPreference(prefs.timezone);
    } catch (_) {
      // Ohne geladene Praeferenz bleibt die Geraetezeitzone aktiv.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setPreference(String? timezone) async {
    final scope = AppScope.of(context);
    try {
      await scope.user.updatePreferences({'timezone': timezone});
      scope.timeZones.setPreference(timezone);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zeitzone konnte nicht gespeichert werden')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final timeZones = AppScope.of(context).timeZones;
    final preference = timeZones.effective;

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'Zeitzone',
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
                      'Anzeige & neue Einträge',
                      style: DesignTextStyle.label,
                      color: tokens.primary,
                    ),
                  ),
                  DesignCard.list(
                    children: [
                      DesignListTile(
                        leading: Icon(
                          Icons.public_rounded,
                          color: tokens.textHigh,
                        ),
                        title: 'Zeitzone',
                        subtitle: _loading ? 'Lädt…' : preference,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _loading
                            ? null
                            : () async {
                                final picked = await showTimeZoneSheet(
                                  context: context,
                                  value: preference,
                                );
                                if (picked != null) {
                                  await _setPreference(picked);
                                }
                              },
                      ),
                      DesignListTile(
                        leading: Icon(
                          Icons.phone_android_rounded,
                          color: tokens.textHigh,
                        ),
                        title: 'Gerätezeitzone verwenden',
                        subtitle: timeZones.device,
                        trailing: Icon(
                          preference == timeZones.device
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: preference == timeZones.device
                              ? tokens.primary
                              : tokens.textLow,
                        ),
                        onTap: _loading ? null : () => _setPreference(null),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceMd),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
                    child: DesignText(
                      'Neue Termine, Reisen und Events erhalten standardmäßig '
                      'diese Zeitzone; die Zeitzone lässt sich beim Erstellen '
                      'und Bearbeiten pro Eintrag ändern.',
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
