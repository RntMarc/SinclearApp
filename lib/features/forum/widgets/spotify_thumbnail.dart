import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/utils/spotify_helper.dart';

/// Compact Spotify thumbnail for feed cards. Fetches album art via the
/// oEmbed API and displays it with track/album info.
class SpotifyThumbnail extends StatefulWidget {
  final SpotifyItem item;
  final String originalUrl;

  const SpotifyThumbnail({
    super.key,
    required this.item,
    required this.originalUrl,
  });

  @override
  State<SpotifyThumbnail> createState() => _SpotifyThumbnailState();
}

class _SpotifyThumbnailState extends State<SpotifyThumbnail> {
  SpotifyOEmbedData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final uri = Uri.https(
        'open.spotify.com',
        '/oembed',
        {'url': widget.originalUrl},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && mounted) {
        // oEmbed returns JSON with thumbnail_url, title, provider_name
        final json = _parseJson(res.body);
        setState(() {
          _data = SpotifyOEmbedData(
            thumbnailUrl: json['thumbnail_url'] ?? '',
            title: json['title'] ?? '',
            artistName: json['provider_name'] ?? 'Spotify',
          );
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _parseJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1DB954).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Album art thumbnail
          if (_data != null && _data!.thumbnailUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Image.network(
                _data!.thumbnailUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                  child: const Icon(Icons.music_note_rounded, size: 32),
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF1DB954),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          // Track info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Spotify',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF1DB954),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_data != null) ...[
                    Text(
                      _data!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _data!.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else
                    Text(
                      Uri.tryParse(widget.originalUrl)?.host ?? 'Spotify',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          Icon(
            Icons.open_in_new_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
