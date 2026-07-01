import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/youtube_helper.dart';

/// Full YouTube player embed for the detail screen. Uses an iframe URL
/// opened via url_launcher (works on mobile + web). A future enhancement
/// could swap this for youtube_player_iframe for inline playback.
class YouTubePlayerEmbed extends StatelessWidget {
  final String videoId;

  const YouTubePlayerEmbed({super.key, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbnailUrl = YoutubeHelper.thumbnailUrl(videoId);
    final embedUrl = YoutubeHelper.embedUrl(videoId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail with play button
        GestureDetector(
          onTap: () => launchUrl(Uri.parse(embedUrl)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  thumbnailUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 220,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 220,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.error_outline, size: 48),
                    );
                  },
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
        const SizedBox(height: 8),
        // Link to open in browser
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => launchUrl(Uri.parse(embedUrl)),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Im Browser öffnen'),
          ),
        ),
      ],
    );
  }
}
