import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassNavigationBar extends StatelessWidget {
  const GlassNavigationBar({
    super.key,
    required this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.width,
    this.padding,
    this.margin,
  });

  final List<NavigationRailDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      type: GlassType.navigationBar,
      width: width ?? 80.0,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8.0),
      margin: margin,
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: Colors.transparent,
        destinations: destinations,
      ),
    );
  }
}
