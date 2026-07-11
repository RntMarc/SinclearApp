import 'package:flutter/material.dart';

import '../../theme/beyond_theme.dart';
import '../../tokens/beyond_tokens.dart';
import '../../tokens/beyond_typography.dart';

/// Catalog text style variants, mapped 1:1 to [BeyondTypography].
enum BeyondTextKind {
  display,
  titleLarge,
  titleMedium,
  headline,
  bodyLarge,
  bodyMedium,
  bodySmall,
  label,
  labelSmall,
}

/// The single text widget of the catalog. Each screen reaches for this instead
/// of raw [Text] so type, color and the optional brand-gradient treatment stay
/// consistent. Convenience subclasses ([BeyondTitle], [BeyondHeadline],
/// [BeyondBody], [BeyondLabel]) cover the common cases.
class BeyondText extends StatelessWidget {
  final String data;
  final BeyondTextKind kind;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool brandGradient;
  final FontWeight? weight;

  const BeyondText(
    this.data, {
    super.key,
    this.kind = BeyondTextKind.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.brandGradient = false,
    this.weight,
  });

  TextStyle _style(BeyondColors c) {
    final t = BeyondTypography.forColors(c);
    final base = switch (kind) {
      BeyondTextKind.display => t.display,
      BeyondTextKind.titleLarge => t.titleLarge,
      BeyondTextKind.titleMedium => t.titleMedium,
      BeyondTextKind.headline => t.headline,
      BeyondTextKind.bodyLarge => t.bodyLarge,
      BeyondTextKind.bodyMedium => t.bodyMedium,
      BeyondTextKind.bodySmall => t.bodySmall,
      BeyondTextKind.label => t.label,
      BeyondTextKind.labelSmall => t.labelSmall,
    };
    return base.copyWith(color: color, fontWeight: weight);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    final style = _style(tokens.color);
    final text = Text(
      data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );

    if (brandGradient) {
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => BeyondBrand.signature.createShader(rect),
        child: text,
      );
    }
    return text;
  }
}

class BeyondDisplay extends BeyondText {
  const BeyondDisplay(
    super.data, {
    super.key,
    super.color,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.brandGradient,
    super.weight,
  }) : super(kind: BeyondTextKind.display);
}

class BeyondTitle extends BeyondText {
  const BeyondTitle(
    super.data, {
    super.key,
    super.color,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.brandGradient,
    super.weight,
  }) : super(kind: BeyondTextKind.titleLarge);
}

class BeyondHeadline extends BeyondText {
  const BeyondHeadline(
    super.data, {
    super.key,
    super.color,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.brandGradient,
    super.weight,
  }) : super(kind: BeyondTextKind.headline);
}

class BeyondBody extends BeyondText {
  const BeyondBody(
    super.data, {
    super.key,
    super.color,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.brandGradient,
    super.weight,
  }) : super(kind: BeyondTextKind.bodyMedium);
}

class BeyondLabel extends BeyondText {
  const BeyondLabel(
    super.data, {
    super.key,
    super.color,
    super.textAlign,
    super.maxLines,
    super.overflow,
    super.brandGradient,
    super.weight,
  }) : super(kind: BeyondTextKind.label);
}
