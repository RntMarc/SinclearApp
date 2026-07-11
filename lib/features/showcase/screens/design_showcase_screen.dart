import 'package:flutter/material.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_nav_item.dart';
import '../../../design/widgets/composite/design_segmented_switch.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../../design/widgets/showcase/design_color_swatch.dart';
import '../../../design/widgets/showcase/design_showcase_section.dart';
import '../../../design/widgets/showcase/design_token_spec.dart';

/// The Design Showcase screen. It demonstrates every widget from the shared
/// catalog under the currently selected design and lets the user switch between
/// the three directions in memory. The rest of the app is untouched.
class DesignShowcaseScreen extends StatelessWidget {
  const DesignShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _Branding(),
                SizedBox(height: tokens.spaceLg),
                const DesignSegmentedSwitch(),
                SizedBox(height: tokens.spaceXl),
                DesignShowcaseSection(
                  title: 'Farbschema',
                  description: 'Variablenbasiert, nie hart codiert.',
                  child: DesignColorSwatch(),
                ),
                SizedBox(height: tokens.spaceLg),
                DesignShowcaseSection(
                  title: 'Token-Spezifikation',
                  description: 'Maße aller Widgets für dieses Design.',
                  child: DesignTokenSpec(),
                ),
                SizedBox(height: tokens.spaceLg),
                DesignShowcaseSection(
                  title: 'Buttons',
                  description: 'Filled, Outlined, Ghost, Patterned (Welle).',
                  child: _buttons(context),
                ),
                SizedBox(height: tokens.spaceLg),
                DesignShowcaseSection(
                  title: 'Chips & Badges', child: _chipsBadges(),
                ),
                SizedBox(height: tokens.spaceLg),
                DesignShowcaseSection(
                  title: 'Eingabefeld',
                  child: DesignTextField(hint: 'Deine Nachricht …'),
                ),
                SizedBox(height: tokens.spaceLg),
                DesignShowcaseSection(
                  title: 'Karten', child: _cards(),
                ),
                SizedBox(height: tokens.spaceLg),
                DesignShowcaseSection(
                  title: 'Avatare & Aktionen', child: _avatarsActions(),
                ),
                SizedBox(height: tokens.spaceLg),
                DesignShowcaseSection(
                  title: 'Liste', child: _listTiles(),
                ),
                SizedBox(height: tokens.spaceLg),
                DesignShowcaseSection(
                  title: 'Navigation', child: _nav(),
                ),
                SizedBox(height: tokens.spaceLg),
                DesignShowcaseSection(
                  title: 'App-Bar (Beispiel)', child: _appBarSample(),
                ),
                SizedBox(height: tokens.spaceLg),
                DesignShowcaseSection(
                  title: 'Bottom Sheet', child: _sheetTrigger(context),
                ),
                SizedBox(height: tokens.spaceXxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        DesignButton(label: 'Filled', onPressed: () {}),
        DesignButton(
          label: 'Outlined',
          variant: DesignButtonVariant.outlined,
          onPressed: () {},
        ),
        DesignButton(
          label: 'Ghost',
          variant: DesignButtonVariant.ghost,
          onPressed: () {},
        ),
        DesignButton(
          label: 'Welle',
          variant: DesignButtonVariant.patterned,
          icon: Icons.auto_awesome_rounded,
          onPressed: () {},
        ),
        const DesignButton(label: 'Deaktiviert', onPressed: null),
      ],
    );
  }

  Widget _chipsBadges() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: const <Widget>[
        DesignChip(label: 'Aktiv', selected: true),
        DesignChip(label: 'Musik'),
        DesignChip(label: 'Reisen'),
        DesignBadge(label: 'Bald'),
        DesignBadge(label: '99+'),
      ],
    );
  }

  Widget _cards() {
    return Column(
      children: <Widget>[
        DesignCard(
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    DesignText(
                      'Beispielkarte',
                      style: DesignTextStyle.subtitle,
                    ),
                    SizedBox(height: 4),
                    DesignText(
                      'Inhalt, die auf dem Surface liegt.',
                      style: DesignTextStyle.body,
                    ),
                  ],
                ),
              ),
              DesignButton(label: 'Los', onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DesignCard(
          onTap: () {},
          child: const DesignText(
            'Klickbare Karte (PressScale-Feedback).',
            style: DesignTextStyle.body,
          ),
        ),
      ],
    );
  }

  Widget _avatarsActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        const DesignAvatar(name: 'Mara König', size: 48),
        const DesignAvatar(name: 'Jonas', size: 40),
        DesignIconButton(
          icon: Icons.favorite_rounded,
          tinted: true,
          onPressed: () {},
        ),
        DesignIconButton(icon: Icons.share_rounded, onPressed: () {}),
        DesignIconButton(icon: Icons.bookmark_rounded, onPressed: () {}),
      ],
    );
  }

  Widget _listTiles() {
    return Column(
      children: <Widget>[
        const DesignListTile(
          leading: DesignAvatar(name: 'Lena', size: 40),
          title: 'Lena Schmidt',
          subtitle: 'Online',
          trailing: DesignBadge(label: 'Freund'),
        ),
        const DesignDivider(),
        DesignListTile(
          leading: const DesignAvatar(name: 'Tom', size: 40),
          title: 'Tom Berger',
          subtitle: 'Feature-Vorschlag',
          trailing: DesignIconButton(
            icon: Icons.chevron_right_rounded,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _nav() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: const <Widget>[
        DesignNavItem(icon: Icons.home_rounded, label: 'Start', active: true),
        DesignNavItem(icon: Icons.explore_rounded, label: 'Entdecken'),
        DesignNavItem(icon: Icons.people_rounded, label: 'Gemeinschaft'),
      ],
    );
  }

  Widget _appBarSample() {
    return DesignAppBar(
      title: 'Beispiel',
      leading: DesignIconButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () {},
      ),
      actions: <Widget>[
        DesignIconButton(icon: Icons.search_rounded, onPressed: () {}),
        DesignIconButton(
          icon: Icons.notifications_rounded,
          tinted: true,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _sheetTrigger(BuildContext context) {
    return DesignButton(
      label: 'Sheet öffnen',
      icon: Icons.visibility_rounded,
      onPressed: () {
        showDesignSheet(
          context: context,
          child: const Column(
            children: <Widget>[
              DesignText(
                'Design-konformantes Sheet',
                style: DesignTextStyle.title,
              ),
              SizedBox(height: 12),
              DesignText(
                'Dieses Sheet nutzt Glas oder Surface des aktiven Designs.',
                style: DesignTextStyle.body,
              ),
              SizedBox(height: 20),
              DesignButton(
                label: 'Schließen',
                fullWidth: true,
                onPressed: null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Branding extends StatelessWidget {
  const _Branding();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Row(
      children: <Widget>[
        Image.asset('assets/logo.png', width: 44, height: 44),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DesignText(
              'Beyond',
              style: DesignTextStyle.display,
              color: tokens.textHigh,
            ),
            DesignText(
              'by Sinclear · Design Showcase',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
        ),
      ],
    );
  }
}
