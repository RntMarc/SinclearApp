import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';

/// Hairline divider that uses the design's [DesignTokens.divider] color.
class DesignDivider extends StatelessWidget {
  const DesignDivider({this.indent, super.key});

  final double? indent;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: indent ?? 0),
      child: Divider(color: tokens.divider, height: 1, thickness: 1),
    );
  }
}
