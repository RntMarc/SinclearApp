import 'package:flutter/material.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Circular avatar showing an image or initials. Builds on the token palette
/// for the fallback background and supports HTTP(S), `data:` and raw base64
/// image sources via [resolveImageProvider].
class DesignAvatar extends StatelessWidget {
  const DesignAvatar({
    this.imageUrl,
    this.name = '',
    this.size = 48,
    super.key,
  });

  final String? imageUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '';
    final provider = resolveImageProvider(imageUrl);
    final child = provider == null
        ? _initials(tokens, initials, size)
        : ClipOval(
            child: Image(
              image: provider,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initials(tokens, initials, size),
            ),
          );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tokens.border.withValues(alpha: 0.6)),
        boxShadow: tokens.surfaceShadow,
      ),
      child: ClipOval(child: child),
    );
  }

  Widget _initials(DesignTokens tokens, String initials, double size) {
    return Container(
      width: size,
      height: size,
      color: tokens.surfaceVariant,
      alignment: Alignment.center,
      child: DesignText(
        initials,
        style: DesignTextStyle.label,
        color: tokens.primary,
      ),
    );
  }
}
