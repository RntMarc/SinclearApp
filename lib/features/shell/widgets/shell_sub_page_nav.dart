import 'package:flutter/material.dart';
import '../../../design/theme/design_theme.dart';
import '../shell_page_config.dart';

class ShellSubPageNav extends StatelessWidget {
  final ShellNavCategory category;
  final int activePageIndex;
  final ValueChanged<int> onPageTap;

  const ShellSubPageNav({
    super.key,
    required this.category,
    required this.activePageIndex,
    required this.onPageTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final pageIndices = indicesForCategory(category);

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          top: BorderSide(
            color: tokens.border.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm),
        children: pageIndices.map((index) {
          final entry = allPages[index];
          final isActive = index == activePageIndex;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceXs,
              vertical: 4,
            ),
            child: _Pill(
              label: entry.label,
              icon: entry.icon,
              isActive: isActive,
              isPlaceholder: entry.isPlaceholder,
              onTap: entry.isPlaceholder ? null : () => onPageTap(index),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isPlaceholder;
  final VoidCallback? onTap;

  const _Pill({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isPlaceholder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    final bgColor = isActive ? tokens.primary : Colors.transparent;
    final fgColor = isActive ? tokens.onPrimary : tokens.textLow;
    final borderColor = isActive
        ? Colors.transparent
        : tokens.border.withValues(alpha: 0.5);
    final opacity = isPlaceholder ? 0.4 : 1.0;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(tokens.radiusPill),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fgColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
