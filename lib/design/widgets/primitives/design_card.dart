import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_glass.dart';
import 'press_scale.dart';

/// Raised surface container. Glass-first designs render it as a frosted panel,
/// others as a solid surface with a soft shadow. Builds on [DesignGlass].
///
/// Use [DesignCard.list] for vertically stacked children (e.g. list tiles)
/// where consistent edge and inter-item spacing is needed.
///
/// The [margin] wraps the entire card (including decoration/shadow) with
/// external spacing. Defaults to [DesignTokens.spaceLg] so cards maintain a
/// consistent distance from screen edges. Pass `EdgeInsets.zero` to opt out.
class DesignCard extends StatelessWidget {
  const DesignCard({
    this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.useGlass,
    this.spacing,
    super.key,
  })  : children = null,
        _isList = false;

  /// List mode – renders [children] vertically separated by [spacing].
  ///
  /// Each child is separated by a [SizedBox] of the given height, and the
  /// whole group is wrapped in horizontal padding. Vertical padding is also
  /// applied so edge and inter-item spacing stay visually balanced.
  const DesignCard.list({
    required List<Widget> this.children,
    this.spacing,
    this.margin,
    this.onTap,
    this.useGlass,
    super.key,
  })  : child = null,
        padding = null,
        _isList = true;

  /// Single child mode (default).
  final Widget? child;

  /// Children mode – only set by [DesignCard.list].
  final List<Widget>? children;

  /// Spacing between list children. Defaults to [DesignTokens.spaceMd].
  final double? spacing;

  final EdgeInsetsGeometry? padding;

  /// External spacing around the card. Defaults to
  /// `EdgeInsets.symmetric(horizontal: tokens.spaceLg)`. Pass
  /// `EdgeInsets.zero` to remove the default margin.
  final EdgeInsetsGeometry? margin;

  final VoidCallback? onTap;
  final bool? useGlass;
  final bool _isList;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final glass = useGlass ?? tokens.useGlass;

    final Widget inner;
    if (_isList) {
      final gap = spacing ?? tokens.spaceMd;
      final separated = <Widget>[];
      for (var i = 0; i < children!.length; i++) {
        if (i > 0) separated.add(SizedBox(height: gap));
        separated.add(children![i]);
      }
      inner = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLg,
          vertical: tokens.spaceMd,
        ),
        child: Column(children: separated),
      );
    } else {
      inner = Padding(
        padding: padding ?? EdgeInsets.all(tokens.spaceLg),
        child: child,
      );
    }

    Widget result;
    if (glass) {
      result = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          boxShadow: tokens.surfaceShadow,
        ),
        child: DesignGlass(child: inner),
      );
    } else {
      result = Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: Border.all(color: tokens.border.withValues(alpha: 0.5)),
          boxShadow: tokens.surfaceShadow,
        ),
        child: inner,
      );
      if (onTap != null) {
        result = PressScale(onTap: onTap, child: result);
      }
    }

    final effectiveMargin =
        margin ?? EdgeInsets.symmetric(horizontal: tokens.spaceLg);
    result = Padding(padding: effectiveMargin, child: result);
    return result;
  }
}
