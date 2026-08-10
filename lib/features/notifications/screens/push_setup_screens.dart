import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';

final _distributorLinks = <(String, Uri)>[
  ('ntfy', Uri.parse('https://f-droid.org/en/packages/io.heckel.ntfy/')),
  (
    'Gotify (UP)',
    Uri.parse('https://f-droid.org/en/packages/de.rincewind.gotify.upserver/'),
  ),
  (
    'NextPush',
    Uri.parse(
      'https://f-droid.org/en/packages/org.unifiedpush.distributor.nextpush/',
    ),
  ),
];

/// Zeigt die gefundenen UnifiedPush-Distributoren als Auswahl-Sheet.
Future<void> showDistributorPickerSheet({
  required BuildContext context,
  required List<String> distributors,
  required Future<void> Function(String distributor) onSelect,
}) async {
  await showDesignSheet<void>(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DesignText(
          'Push-Distributor wählen',
          style: DesignTextStyle.subtitle,
        ),
        const SizedBox(height: 8),
        const DesignText(
          'Die App braucht einen UnifiedPush-Distributor, um Push-Mitteilungen '
          'zu empfangen. Wähle eine installierte App:',
          style: DesignTextStyle.body,
        ),
        const SizedBox(height: 12),
        for (final name in distributors)
          DesignListTile(
            leading: const Icon(Icons.push_pin_rounded),
            title: name,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.pop(context);
              onSelect(name);
            },
          ),
      ],
    ),
  );
}

/// Erscheint, wenn kein UnifiedPush-Distributor installiert ist. Bietet die
/// empfohlenen Distributoren als Store-Links an; „Ohne UnifiedPush
/// fortfahren" führt zur Akku-Hinweis-Seite.
class NoDistributorScreen extends StatelessWidget {
  const NoDistributorScreen({super.key});

  Future<void> _openLink(BuildContext context, Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      withGrain: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const DesignAppBar(title: 'Push-Benachrichtigungen'),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceXl,
                vertical: tokens.spaceXl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 56,
                      color: tokens.primary,
                    ),
                    SizedBox(height: tokens.spaceXl),
                    const DesignText(
                      'Kein Push-Distributor gefunden',
                      style: DesignTextStyle.subtitle,
                    ),
                    SizedBox(height: tokens.spaceXs),
                    const DesignText(
                      'Für zuverlässige Push-Mitteilungen im Hintergrund '
                      'installiere einen UnifiedPush-Distributor. Empfohlen '
                      'werden:',
                      style: DesignTextStyle.body,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    DesignCard.list(
                      children: [
                        for (final (name, uri) in _distributorLinks)
                          DesignListTile(
                            leading: const Icon(Icons.download_rounded),
                            title: name,
                            trailing: const Icon(Icons.open_in_new_rounded),
                            onTap: () => _openLink(context, uri),
                          ),
                      ],
                    ),
                    SizedBox(height: tokens.spaceLg),
                    DesignButton(
                      label: 'Ohne UnifiedPush fortfahren',
                      variant: DesignButtonVariant.outlined,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const PollingHintScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Akku-Hinweise für Hersteller, die Hintergrund-Polling aggressiv beenden.
class PollingHintScreen extends StatelessWidget {
  const PollingHintScreen({super.key});

  Future<void> _openDontKillMyApp(BuildContext context) async {
    await launchUrl(
      Uri.parse('https://dontkillmyapp.com/'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      withGrain: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const DesignAppBar(title: 'Akku-Einstellungen'),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceXl,
                vertical: tokens.spaceXl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.battery_saver_rounded,
                      size: 56,
                      color: tokens.warning,
                    ),
                    SizedBox(height: tokens.spaceXl),
                    const DesignText(
                      'Mitteilungen ohne UnifiedPush',
                      style: DesignTextStyle.subtitle,
                    ),
                    SizedBox(height: tokens.spaceXs),
                    const DesignText(
                      'Ohne Push-Distributor empfängt die App Mitteilungen '
                      'über regelmäßiges Abrufen. Damit das auch im '
                      'Hintergrund funktioniert, erlaube der App '
                      'Hintergrundaktivität:',
                      style: DesignTextStyle.body,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    const _HintCard(
                      title: 'Standard Android',
                      body:
                          'Android 12+: Einstellungen → Apps → Beyond → '
                          'Akku → „Uneingeschränkt“. Android 6+: Doze '
                          'deaktivieren („Akkuoptimierung ignorieren“).',
                    ),
                    SizedBox(height: tokens.spaceMd),
                    const _HintCard(
                      title: 'Samsung',
                      body:
                          'Einstellungen → Akku → Hintergrund-Nutzung → '
                          '„Schlafende Apps nie“ – Beyond dorthin verschieben.',
                    ),
                    SizedBox(height: tokens.spaceMd),
                    const _HintCard(
                      title: 'Xiaomi',
                      body:
                          'Einstellungen → Apps → Beyond → Autostart '
                          'aktivieren und „Keine Einschränkungen“ als '
                          'Akku-Modus wählen.',
                    ),
                    SizedBox(height: tokens.spaceMd),
                    const _HintCard(
                      title: 'OnePlus',
                      body: 'App-Info → Akku → „Optimierung nicht anwenden“.',
                    ),
                    SizedBox(height: tokens.spaceLg),
                    Center(
                      child: DesignButton(
                        label: 'Mehr Geräte-Hinweise',
                        variant: DesignButtonVariant.text,
                        onPressed: () => _openDontKillMyApp(context),
                      ),
                    ),
                    SizedBox(height: tokens.spaceXs),
                    DesignButton(
                      label: 'Fertig',
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String title;
  final String body;

  const _HintCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(title, style: DesignTextStyle.label),
          SizedBox(height: tokens.spaceXs),
          DesignText(body, style: DesignTextStyle.body, color: tokens.textLow),
        ],
      ),
    );
  }
}
