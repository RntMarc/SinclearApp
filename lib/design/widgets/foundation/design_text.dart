import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';

/// Text style tiers available across the catalog.
enum DesignTextStyle { display, title, subtitle, body, label }

/// Typography wrapper that resolves its style from the active [DesignTokens].
///
/// All catalog text goes through this so font family, weight and color stay
/// consistent with the selected design.
class DesignText extends StatelessWidget {
  const DesignText(
    this.text, {
    this.style = DesignTextStyle.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    super.key,
  });

  final String text;
  final DesignTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final baseColor = color ?? tokens.textHigh;
    final textStyle = switch (style) {
      DesignTextStyle.display => tokens.displayStyle(baseColor),
      DesignTextStyle.title => tokens.titleStyle(baseColor),
      DesignTextStyle.subtitle => tokens.subtitleStyle(baseColor),
      DesignTextStyle.label => tokens.labelStyle(baseColor),
      DesignTextStyle.body => tokens.bodyStyle(baseColor),
    };
    return Text(
      text,
      style: textStyle.copyWith(letterSpacing: letterSpacing),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
