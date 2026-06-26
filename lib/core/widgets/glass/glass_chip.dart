import 'package:flutter/material.dart';
import 'glass_container.dart';

class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    this.avatar,
    required this.label,
    this.onDeleted,
    this.deleteIcon,
    this.padding,
    this.visualDensity,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.side,
    this.shape,
    this.backgroundColor,
  });

  final Widget? avatar;
  final Widget label;
  final VoidCallback? onDeleted;
  final Widget? deleteIcon;
  final EdgeInsetsGeometry? padding;
  final VisualDensity? visualDensity;
  final MaterialTapTargetSize? materialTapTargetSize;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final BorderSide? side;
  final OutlinedBorder? shape;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      type: GlassType.chip,
      child: Chip(
        avatar: avatar,
        label: label,
        onDeleted: onDeleted,
        deleteIcon: deleteIcon,
        padding: padding,
        visualDensity: visualDensity,
        materialTapTargetSize: materialTapTargetSize,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        side: BorderSide.none,
        shape: shape,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
