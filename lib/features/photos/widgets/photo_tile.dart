import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../models/photo_models.dart';

/// Eine Masonry-Kachel für ein einzelnes Foto.
///
/// Zeigt das Bild im natürlichen Seitenverhältnis (`thumb`-URL) und blendet
/// unten dezent den Fotografen ein (Attribution gemäß Unsplash-Richtlinien).
class PhotoTile extends StatelessWidget {
  final Photo photo;
  final VoidCallback onTap;

  const PhotoTile({super.key, required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return PressScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: AspectRatio(
          aspectRatio: photo.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _PhotoImage(url: photo.thumb, tokens: tokens),
              if (photo.photographer.displayName != null)
                _CreditOverlay(name: photo.photographer.displayName!),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  final String? url;
  final DesignTokens tokens;

  const _PhotoImage({required this.url, required this.tokens});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return ColoredBox(color: tokens.surfaceVariant);
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, _) => ColoredBox(color: tokens.surfaceVariant),
      errorWidget: (_, _, _) => ColoredBox(
        color: tokens.surfaceVariant,
        child: Icon(Icons.broken_image_rounded, color: tokens.textLow),
      ),
    );
  }
}

class _CreditOverlay extends StatelessWidget {
  final String name;

  const _CreditOverlay({required this.name});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 18, 8, 6),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        child: DesignText(
          name,
          style: DesignTextStyle.label,
          color: Colors.white,
          maxLines: 1,
        ),
      ),
    );
  }
}
