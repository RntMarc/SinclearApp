import 'package:flutter/material.dart';

class GlassNavigationDestination extends StatelessWidget {
  const GlassNavigationDestination({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
  });

  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;

  @override
  Widget build(BuildContext context) {
    return NavigationDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      label: label,
      tooltip: tooltip,
    );
  }
}
