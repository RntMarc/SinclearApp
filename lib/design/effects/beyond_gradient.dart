import 'package:flutter/material.dart';

import '../theme/beyond_theme.dart';
import '../tokens/beyond_tokens.dart';
import 'beyond_grain.dart';

/// Paints the signature blue->magenta brand gradient as a background and overlays
/// the film-grain texture so gradient surfaces feel tactile.
class BeyondGradientBackground extends StatelessWidget {
  final Widget child;
  final Alignment begin;
  final Alignment end;

  const BeyondGradientBackground({
    super.key,
    required this.child,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    return ClipRRect(
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: BeyondBrand.signatureFrom(begin, end),
            ),
            child: child,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: BeyondGrainTexture(opacity: tokens.grainOpacity),
            ),
          ),
        ],
      ),
    );
  }
}
