import 'package:flutter/material.dart';

import '../../effects/beyond_glass.dart';
import '../../theme/beyond_theme.dart';
import 'beyond_brand_logo.dart';
import 'beyond_list_tile.dart';
import 'beyond_text.dart';

/// A single navigation entry (icon + label), reused in the sidebar and in
/// category sheets. Wraps [BeyondListTile] so selection styling is shared.
class BeyondNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  const BeyondNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => BeyondListTile(
        leading: Icon(icon),
        title: label,
        selected: selected,
        onTap: onTap,
        trailing: trailing,
      );
}

/// Small uppercase category label used to group sidebar entries.
class BeyondCategoryHeader extends StatelessWidget {
  final String title;

  const BeyondCategoryHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.lg,
        tokens.spacing.lg,
        tokens.spacing.lg,
        tokens.spacing.xs,
      ),
      child: BeyondText(
        title,
        kind: BeyondTextKind.labelSmall,
        color: tokens.color.brandBlue,
      ),
    );
  }
}

/// Destination for the mobile bottom navigation bar.
class BeyondNavDestination {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const BeyondNavDestination({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
}

/// Floating glass bottom navigation bar.
class BeyondBottomNav extends StatelessWidget {
  final List<BeyondNavDestination> destinations;

  const BeyondBottomNav({super.key, required this.destinations});

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    return Padding(
      padding: EdgeInsets.all(tokens.spacing.md),
      child: BeyondGlass(
        borderRadius: BorderRadius.circular(tokens.radius.xl),
        glow: true,
        padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
        child: Row(
          children: destinations
              .map(
                (d) => Expanded(
                  child: InkWell(
                    onTap: d.onTap,
                    borderRadius: BorderRadius.circular(tokens.radius.md),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: tokens.spacing.xs),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            d.icon,
                            size: 22,
                            color: d.active
                                ? tokens.color.brandBlue
                                : tokens.color.onSurfaceVariant,
                          ),
                          SizedBox(height: tokens.spacing.xs),
                          BeyondText(
                            d.label,
                            kind: BeyondTextKind.labelSmall,
                            color: d.active
                                ? tokens.color.brandBlue
                                : tokens.color.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// Glass desktop sidebar. Compose its children (brand logo, headers, nav items)
/// from the shell so navigation rules stay in one place.
class BeyondSidebar extends StatelessWidget {
  final List<Widget> children;
  final double width;

  const BeyondSidebar({
    super.key,
    required this.children,
    this.width = 288,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    return SizedBox(
      width: width,
      child: BeyondGlass(
        borderRadius: BorderRadius.zero,
        blurSigma: tokens.glass.blurSigma,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience brand header for the top of the sidebar.
class BeyondSidebarBrand extends StatelessWidget {
  const BeyondSidebarBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.lg,
        tokens.spacing.xl,
        tokens.spacing.lg,
        tokens.spacing.md,
      ),
      child: const BeyondBrandLogo(),
    );
  }
}
