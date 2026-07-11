import 'package:flutter/material.dart';

import '../../effects/beyond_glass.dart';

/// Frosted-glass card. Built directly on [BeyondGlass] so it inherits the blur,
/// hairline stroke and glow behavior. This is the default container for all
/// content blocks.
class BeyondCard extends BeyondGlass {
  const BeyondCard({
    super.key,
    super.child,
    super.padding = const EdgeInsets.all(16),
    super.borderRadius,
    super.blurSigma,
    super.glow,
    super.brandedBorder,
    super.fill,
  });
}
