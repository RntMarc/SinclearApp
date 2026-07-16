import 'package:flutter/material.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';

const _labels = <int, String>{0: 'Nur ich', 1: 'Alle', 2: 'Freunde'};
const _icons = <int, IconData>{
  0: Icons.lock_rounded,
  1: Icons.public_rounded,
  2: Icons.people_rounded,
};

class VisibilityBadge extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const VisibilityBadge({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final label = _labels[value] ?? 'Unbekannt';
    final icon = _icons[value] ?? Icons.help_outline;

    return Material(
      type: MaterialType.transparency,
      child: PopupMenuButton<int>(
        onSelected: onChanged,
        offset: const Offset(0, 32),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tokens.surfaceVariant,
            borderRadius: BorderRadius.circular(tokens.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: tokens.primary),
              const SizedBox(width: 4),
              DesignText(
                label,
                style: DesignTextStyle.label,
                color: tokens.primary,
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: tokens.primary,
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 0,
            child: _Item(
              label: 'Nur ich',
              subtitle: 'Niemand außer dir',
              icon: _icons[0]!,
            ),
          ),
          PopupMenuItem(
            value: 1,
            child: _Item(
              label: 'Alle',
              subtitle: 'Jeder eingeloggte Nutzer',
              icon: _icons[1]!,
            ),
          ),
          PopupMenuItem(
            value: 2,
            child: _Item(
              label: 'Enge Freunde',
              subtitle: 'Nur von dir hinzugefügte',
              icon: _icons[2]!,
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;

  const _Item({
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: tokens.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DesignText(label, style: DesignTextStyle.body),
            DesignText(
              subtitle,
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
        ),
      ],
    );
  }
}
