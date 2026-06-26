import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassBottomNavigationBar extends StatelessWidget {
  const GlassBottomNavigationBar({
    super.key,
    required this.items,
    this.currentIndex = 0,
    this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedFontSize,
    this.unselectedFontSize,
    this.type,
    this.elevation,
    this.showSelectedLabels,
    this.showUnselectedLabels,
    this.mouseCursor,
    this.enableFeedback,
    this.mouseCursorOnHover,
  });

  final List<BottomNavigationBarItem> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? selectedFontSize;
  final double? unselectedFontSize;
  final BottomNavigationBarType? type;
  final double? elevation;
  final bool? showSelectedLabels;
  final bool? showUnselectedLabels;
  final MouseCursor? mouseCursor;
  final bool? enableFeedback;
  final MouseCursor? mouseCursorOnHover;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: GlassContainer(
        type: GlassType.bottomNav,
        child: BottomNavigationBar(
          items: items,
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
          selectedFontSize: selectedFontSize ?? 12.0,
          unselectedFontSize: unselectedFontSize ?? 12.0,
          type: type ?? BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: showSelectedLabels,
          showUnselectedLabels: showUnselectedLabels,
          mouseCursor: mouseCursor,
          enableFeedback: enableFeedback,
        ),
      ),
    );
  }
}
