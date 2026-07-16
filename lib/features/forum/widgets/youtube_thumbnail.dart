import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/youtube_helper.dart';
import '../../../design/theme/design_theme.dart';

class YouTubeThumbnail extends StatelessWidget {
  final String videoId;
  final double? width;
  final double? height;

  const YouTubeThumbnail({
    super.key,
    required this.videoId,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final thumbnailUrl = YoutubeHelper.thumbnailUrl(videoId);

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusSm),
      child: SizedBox(
        width: width ?? double.infinity,
        height: height ?? 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: thumbnailUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                color: tokens.surfaceVariant,
                child: Center(
                  child: CircularProgressIndicator(color: tokens.primary),
                ),
              ),
              errorWidget: (_, _, _) => Container(
                color: tokens.surfaceVariant,
                child: Icon(Icons.error_outline, size: 32, color: tokens.textLow),
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'YouTube',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
