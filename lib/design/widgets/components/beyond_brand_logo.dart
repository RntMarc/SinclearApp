import 'package:flutter/material.dart';

import '../../theme/beyond_theme.dart';
import '../../tokens/beyond_tokens.dart';

/// Sinclear "Beyond" brand lockup. Shows the platform logo and the word mark,
/// optionally with the signature gradient on the text.
class BeyondBrandLogo extends StatelessWidget {
  final double logoSize;
  final bool gradientWordmark;

  const BeyondBrandLogo({
    super.key,
    this.logoSize = 32,
    this.gradientWordmark = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          'assets/logo.png',
          width: logoSize,
          height: logoSize,
        ),
        SizedBox(width: tokens.spacing.md),
        gradientWordmark
            ? ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (rect) => BeyondBrand.signature.createShader(rect),
                child: const Text(
                  'Beyond',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : Text(
                'Beyond',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: tokens.color.onSurface,
                ),
              ),
      ],
    );
  }
}
