import 'package:flutter/material.dart';

import '../../theme/beyond_theme.dart';
import '../../effects/beyond_grain.dart';

/// Base surface for every screen. Fills with the mode's background color, paints
/// a subtle brand-colored radial glow behind the content, and optionally layers
/// the global film grain on top. Use this instead of a bare [Scaffold] body.
class BeyondSurface extends StatelessWidget {
  final Widget child;
  final bool grain;
  final bool brandGlow;

  const BeyondSurface({
    super.key,
    required this.child,
    this.grain = false,
    this.brandGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;

    final body = Container(
      decoration: BoxDecoration(color: tokens.color.surfaceBase),
      child: brandGlow
          ? Stack(
              children: <Widget>[
                const Positioned.fill(child: _BrandGlow()),
                child,
              ],
            )
          : child,
    );

    return grain ? BeyondGrain(child: body) : body;
  }
}

/// Decorative, very low-opacity brand glow anchored to the top-right corner.
class _BrandGlow extends StatelessWidget {
  const _BrandGlow();

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.3,
          colors: <Color>[
            tokens.color.brandBlue.withValues(alpha: 0.16),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
