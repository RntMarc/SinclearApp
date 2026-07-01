import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/spotify_helper.dart';

/// Full Spotify embed for the detail screen. Shows album art + info and
/// an "Open in Spotify" button. A real iframe embed would require WebView.
class SpotifyPlayerEmbed extends StatelessWidget {
  final SpotifyItem item;
  final String originalUrl;

  const SpotifyPlayerEmbed({
    super.key,
    required this.item,
    required this.originalUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1DB954).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header with Spotify branding
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1DB954),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF1DB954),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        Uri.tryParse(originalUrl)?.host ?? 'Spotify',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => launchUrl(Uri.parse(originalUrl)),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('In Spotify öffnen'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(SpotifyHelper.embedUrl(item.type, item.id)),
                  ),
                  icon: const Icon(Icons.language_rounded, size: 18),
                  label: const Text('Embed'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
