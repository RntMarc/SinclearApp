import 'package:flutter/material.dart';

import '../beyond.dart';

/// Visual catalog of every widget in the Aurora Glass system. Open via
/// `/design-showcase` (see router.dart). Used to verify the design language and
/// as a living reference while screens migrate to the catalog.
class DesignShowcaseScreen extends StatelessWidget {
  const DesignShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;

    return BeyondScaffold(
      appBar: const BeyondAppBar(titleText: 'Design Showcase'),
      body: ListView(
        padding: EdgeInsets.all(tokens.spacing.lg),
        children: <Widget>[
          const BeyondBrandLogo(),
          SizedBox(height: tokens.spacing.xl),
          BeyondSection(
            title: 'Typografie',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                BeyondDisplay('Beyond Display'),
                BeyondTitle('Beyond Title'),
                BeyondHeadline('Beyond Headline'),
                BeyondBody('Beyond Body – der Standard-Flugtext mit angenehmer '
                    'Leselänge und gutem Kontrast.'),
                BeyondLabel('Beyond Label'),
                BeyondText('Gradient Text',
                    kind: BeyondTextKind.headline, brandGradient: true),
              ],
            ),
          ),
          BeyondSection(
            title: 'Buttons',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                BeyondButton(label: 'Primary', onPressed: () {}),
                BeyondButton(
                  label: 'Glass',
                  variant: BeyondButtonVariant.glass,
                  onPressed: () {},
                ),
                BeyondButton(
                  label: 'Ghost',
                  variant: BeyondButtonVariant.ghost,
                  onPressed: () {},
                ),
                BeyondButton(
                  label: 'Loading',
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
          BeyondSection(
            title: 'Chips & Badges',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                BeyondChip(label: 'Tag', icon: Icon(Icons.tag)),
                BeyondChip(label: 'Bald'),
                BeyondBadge(label: '3'),
              ],
            ),
          ),
          BeyondSection(
            title: 'Cards & Avatare',
            child: Row(
              children: <Widget>[
                Expanded(
                  child: BeyondCard(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: BeyondBody('Eine Frost-Glas-Karte mit blur, '
                          'Stroke und weichem Schatten.'),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                BeyondAvatar(name: 'Sinclear Beyond', size: 56, ring: true),
              ],
            ),
          ),
          BeyondSection(
            title: 'Liste',
            child: Column(
              children: <Widget>[
                BeyondNavItem(
                  icon: Icons.forum_rounded,
                  label: 'Forum',
                  selected: true,
                  onTap: () {},
                ),
                BeyondNavItem(
                  icon: Icons.explore_rounded,
                  label: 'Entdecken',
                  onTap: () {},
                ),
              ],
            ),
          ),
          BeyondSection(
            title: 'Leerer Zustand',
            child: BeyondEmptyState(
              icon: Icons.explore_rounded,
              title: 'Noch nichts hier',
              description: 'Sobald Inhalte da sind, erscheinen sie hier.',
              action: BeyondButton(label: 'Aktion', onPressed: () {}),
            ),
          ),
          BeyondSection(
            title: 'Dialog',
            child: BeyondButton(
              label: 'Dialog öffnen',
              variant: BeyondButtonVariant.glass,
              onPressed: () => BeyondDialog.show(
                context: context,
                title: 'Beispiel-Dialog',
                message: 'Dies ist ein Glas-Dialog aus dem Katalog.',
                confirmLabel: 'Ok',
                cancelLabel: 'Abbrechen',
              ),
            ),
          ),
          BeyondSection(
            title: 'Gradient',
            child: SizedBox(
              height: 120,
              child: BeyondGradientBackground(
                child: Center(
                  child: BeyondText(
                    'Signatur-Verlauf',
                    kind: BeyondTextKind.headline,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
