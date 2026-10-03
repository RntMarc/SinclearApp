import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/foundation/design_text.dart';

/// Ziel des gemeinsamen „Neu erstellen"-Menüs auf dem Reisen-Screen.
enum TravelCreateAction {
  tripWithPlanning,
  tripWithoutPlanning,
  standaloneEvent,
  ptSearch,
}

/// Öffnet das Auswahl-Sheet für neue Reisen, Events und die ÖPNV-Suche.
///
/// Liefert die gewählte Aktion oder `null`, wenn abgebrochen wurde. Die
/// Navigation ist bewusst nicht Teil des Sheets, damit dieses rein
/// darstellend bleibt.
Future<TravelCreateAction?> showTravelCreateSheet({
  required BuildContext context,
}) {
  return showDesignSheet<TravelCreateAction>(
    context: context,
    child: const _TravelCreateSheet(),
  );
}

class _TravelCreateSheet extends StatefulWidget {
  const _TravelCreateSheet();

  @override
  State<_TravelCreateSheet> createState() => _TravelCreateSheetState();
}

class _TravelCreateSheetState extends State<_TravelCreateSheet> {
  bool _showTripChoice = false;

  void _select(TravelCreateAction action) => Navigator.pop(context, action);

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          'Neu erstellen',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        _Option(
          icon: Icons.flight_takeoff_rounded,
          title: 'Neue Reise',
          subtitle: 'Gemeinsam planen oder direkt anlegen.',
          trailing: Icon(
            _showTripChoice
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
            color: tokens.textLow,
          ),
          onTap: () => setState(() => _showTripChoice = !_showTripChoice),
        ),
        if (_showTripChoice) ...[
          SizedBox(height: tokens.spaceSm),
          _Option(
            icon: Icons.groups_rounded,
            title: 'Mit Planungsphase',
            subtitle:
                'Legt die Reise in der Planungsphase an. Mitreisende planen '
                'gemeinsam, wann, wie und wo die Reise stattfinden kann.',
            indented: true,
            onTap: () => _select(TravelCreateAction.tripWithPlanning),
          ),
          SizedBox(height: tokens.spaceSm),
          _Option(
            icon: Icons.flight_rounded,
            title: 'Ohne Planungsphase',
            subtitle:
                'Überspringt die Planung. Geeignet für Reisen, die extern '
                'geplant werden oder bereits im Detail feststehen.',
            indented: true,
            onTap: () => _select(TravelCreateAction.tripWithoutPlanning),
          ),
        ],
        SizedBox(height: tokens.spaceSm),
        _Option(
          icon: Icons.event_rounded,
          title: 'Neues Event',
          subtitle:
              'Eigenständiges Event wie ein Tagesausflug ohne übergeordnete '
              'Reise. Events zu einer bestehenden Reise fügst du innerhalb '
              'der Reise hinzu.',
          onTap: () => _select(TravelCreateAction.standaloneEvent),
        ),
        SizedBox(height: tokens.spaceSm),
        _Option(
          icon: Icons.directions_bus_rounded,
          title: 'ÖPNV-Suche',
          subtitle:
              'Sucht Verbindungen zwischen zwei Haltepunkten im ÖPNV-Netz, '
              'die du mit anderen teilen kannst.',
          onTap: () => _select(TravelCreateAction.ptSearch),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.indented = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool indented;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: indented ? tokens.spaceLg : 0),
      child: DesignListTile(
        leading: Icon(icon, color: tokens.primary, size: 22),
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
