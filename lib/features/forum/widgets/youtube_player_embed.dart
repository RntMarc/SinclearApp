import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/youtube_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/primitives/design_button.dart';

class YouTubePlayerEmbed extends StatelessWidget {
  final String videoId;

  const YouTubePlayerEmbed({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final thumbnailUrl = YoutubeHelper.thumbnailUrl(videoId);
    final embedUrl = YoutubeHelper.embedUrl(videoId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => launchUrl(Uri.parse(embedUrl)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    width: double.infinity,
                    height: 220,
                    color: tokens.surfaceVariant,
                    child: Center(
                      child: CircularProgressIndicator(color: tokens.primary),
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    width: double.infinity,
                    height: 220,
                    color: tokens.surfaceVariant,
                    child: Icon(Icons.error_outline, size: 48, color: tokens.textLow),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        Align(
          alignment: Alignment.centerRight,
          child: DesignButton(
            variant: DesignButtonVariant.text,
            icon: Icons.open_in_new_rounded,
            label: 'Im Browser öffnen',
            onPressed: () => launchUrl(Uri.parse(embedUrl)),
          ),
        ),
      ],
    );
  }
}
