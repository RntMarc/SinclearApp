import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/spotify_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';

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
    final tokens = DesignTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1DB954).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(
          color: const Color(0xFF1DB954).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(tokens.spaceLg),
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
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DesignText(
                        item.label,
                        style: DesignTextStyle.label,
                        color: tokens.primary,
                      ),
                      DesignText(
                        Uri.tryParse(originalUrl)?.host ?? 'Spotify',
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border.withValues(alpha: 0.3)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceLg,
              vertical: tokens.spaceSm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: DesignButton(
                    variant: DesignButtonVariant.filled,
                    icon: Icons.open_in_new_rounded,
                    label: 'In Spotify öffnen',
                    onPressed: () => launchUrl(Uri.parse(originalUrl)),
                  ),
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: DesignButton(
                    variant: DesignButtonVariant.outlined,
                    icon: Icons.language_rounded,
                    label: 'Embed',
                    onPressed: () => launchUrl(
                      Uri.parse(SpotifyHelper.embedUrl(item.type, item.id)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
