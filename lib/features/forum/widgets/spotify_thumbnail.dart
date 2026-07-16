import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/spotify_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';

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
    final cached = SpotifyHelper.cachedOEmbed(widget.originalUrl);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _data = cached;
          _loading = false;
        });
      }
      return;
    }

    try {
      final uri = Uri.https(
        'open.spotify.com',
        '/oembed',
        {'url': widget.originalUrl},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200 && mounted) {
        final json = _parseJson(res.body);
        final data = SpotifyOEmbedData(
          thumbnailUrl: json['thumbnail_url'] ?? '',
          title: json['title'] ?? '',
          artistName: json['provider_name'] ?? 'Spotify',
        );
        SpotifyHelper.cacheOEmbed(widget.originalUrl, data);
        setState(() {
          _data = data;
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
    final tokens = DesignTheme.of(context);

    if (_loading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: tokens.surfaceVariant,
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary),
          ),
        ),
      );
    }

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(tokens.radiusSm),
        border: Border.all(
          color: const Color(0xFF1DB954).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (_data != null && _data!.thumbnailUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(tokens.radiusSm),
                bottomLeft: Radius.circular(tokens.radiusSm),
              ),
              child: CachedNetworkImage(
                imageUrl: _data!.thumbnailUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: (_, e, s) => Container(
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
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                            decoration: TextDecoration.none,
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
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceXs),
                  if (_data != null) ...[
                    DesignText(
                      _data!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTextStyle.label,
                      color: tokens.textHigh,
                    ),
                    DesignText(
                      _data!.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                    ),
                  ] else
                    DesignText(
                      Uri.tryParse(widget.originalUrl)?.host ?? 'Spotify',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTextStyle.label,
                      color: tokens.textHigh,
                    ),
                ],
              ),
            ),
          ),
          Icon(Icons.open_in_new_rounded, size: 16, color: tokens.textLow),
          SizedBox(width: tokens.spaceSm),
        ],
      ),
    );
  }
}
