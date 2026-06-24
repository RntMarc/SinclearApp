import 'package:flutter/material.dart';

const _labels = <int, String>{0: 'Nur ich', 1: 'Alle', 2: 'Freunde'};
const _icons = <int, IconData>{
  0: Icons.lock_rounded,
  1: Icons.public_rounded,
  2: Icons.people_rounded,
};

class VisibilityBadge extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const VisibilityBadge({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _labels[value] ?? 'Unbekannt';
    final icon = _icons[value] ?? Icons.help_outline;

    return PopupMenuButton<int>(
      onSelected: onChanged,
      offset: const Offset(0, 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0,
          child: _Item(label: 'Nur ich', subtitle: 'Niemand außer dir', icon: _icons[0]!),
        ),
        PopupMenuItem(
          value: 1,
          child: _Item(label: 'Alle', subtitle: 'Jeder eingeloggte Nutzer', icon: _icons[1]!),
        ),
        PopupMenuItem(
          value: 2,
          child: _Item(label: 'Enge Freunde', subtitle: 'Nur von dir hinzugefügte', icon: _icons[2]!),
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;

  const _Item({required this.label, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
