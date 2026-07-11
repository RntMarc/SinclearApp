import 'package:flutter/material.dart';

import '../../theme/beyond_theme.dart';
import '../../tokens/beyond_tokens.dart';
import 'beyond_text.dart';

class BeyondDivider extends StatelessWidget {
  final double? indent;
  final double? endIndent;

  const BeyondDivider({super.key, this.indent, this.endIndent});

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    return Divider(
      color: tokens.color.borderSubtle,
      thickness: 1,
      height: 1,
      indent: indent,
      endIndent: endIndent,
    );
  }
}

/// Circle avatar with an optional gradient ring. Shows the image when provided,
/// otherwise the initials on a subtle brand-tinted fill.
class BeyondAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final bool ring;

  const BeyondAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.ring = false,
  });

  String get _initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.beyond;
    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.color.surfaceRaised,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: BeyondText(
                _initials,
                kind: BeyondTextKind.label,
                color: tokens.color.onSurfaceVariant,
              ),
            )
          : null,
    );

    if (!ring) return inner;

    return Container(
      width: size + 4,
      height: size + 4,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: BeyondBrand.signature,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: inner,
      ),
    );
  }
}
