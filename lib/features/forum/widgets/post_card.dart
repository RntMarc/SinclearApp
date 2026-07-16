import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../core/utils/spotify_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/forum_models.dart';
import 'youtube_thumbnail.dart';
import 'spotify_thumbnail.dart';
import 'og_preview_card.dart';

class PostCard extends StatelessWidget {
  final FeedPost post;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback onVote;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onTap,
    required this.onVote,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final typeIcon = _typeIcon(post.type);
    final typeLabel = _typeLabel(post.type);

    return DesignCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DesignAvatar(
                imageUrl: post.userImage,
                name: post.userName ?? post.userId,
                size: 32,
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DesignText(
                      post.userName ?? 'Benutzer',
                      style: DesignTextStyle.label,
                      color: tokens.textHigh,
                    ),
                    DesignText(
                      app_date.formatRelativeDate(post.createdAt),
                      style: DesignTextStyle.label,
                      color: tokens.textLow.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              Icon(typeIcon, size: 16, color: tokens.primary),
              SizedBox(width: tokens.spaceXs),
              DesignText(
                typeLabel,
                style: DesignTextStyle.label,
                color: tokens.primary,
              ),
              if (post.userId == currentUserId && onDelete != null)
                DesignIconButton(
                  icon: Icons.more_vert_rounded,
                  onPressed: () {
                    showDesignSheet(
                      context: context,
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DesignText(
                              'Post löschen',
                              style: DesignTextStyle.title,
                              color: tokens.textHigh,
                            ),
                            SizedBox(height: tokens.spaceMd),
                            DesignText(
                              'Möchtest du diesen Post wirklich löschen?',
                              style: DesignTextStyle.body,
                              color: tokens.textHigh,
                            ),
                            SizedBox(height: tokens.spaceLg),
                            Row(
                              children: [
                                Expanded(
                                  child: DesignButton(
                                    variant: DesignButtonVariant.outlined,
                                    label: 'Abbrechen',
                                    onPressed: () =>
                                        Navigator.pop(context),
                                  ),
                                ),
                                SizedBox(width: tokens.spaceSm),
                                Expanded(
                                  child: DesignButton(
                                    variant: DesignButtonVariant.filled,
                                    label: 'Löschen',
                                    onPressed: () {
                                      Navigator.pop(context);
                                      onDelete!();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          if (post.title != null && post.title!.isNotEmpty) ...[
            SizedBox(height: tokens.spaceSm),
            DesignText(
              post.title!,
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (post.text != null && post.text!.isNotEmpty) ...[
            SizedBox(height: tokens.spaceSm),
            DesignText(
              post.text!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (post.type == 'web') ...[
            if (post.youtubeIds.isNotEmpty) ...[
              SizedBox(height: tokens.spaceSm),
              YouTubeThumbnail(videoId: post.youtubeIds.first),
            ],
            if (post.spotifyItems.isNotEmpty) ...[
              SizedBox(height: tokens.spaceSm),
              SpotifyThumbnail(
                item: post.spotifyItems.first,
                originalUrl: post.webUrls.firstWhere(
                  (u) => SpotifyHelper.parseUrl(u) != null,
                  orElse: () => post.webUrls.first,
                ),
              ),
            ],
            if (post.genericUrls.isNotEmpty) ...[
              SizedBox(height: tokens.spaceSm),
              OgPreviewCard(url: post.genericUrls.first),
            ],
          ],
          if (post.type == 'video' && post.youtubeVideoIds.isNotEmpty) ...[
            SizedBox(height: tokens.spaceSm),
            YouTubeThumbnail(videoId: post.youtubeVideoIds.first),
          ],
          if (post.type == 'music' && post.spotifyMusicItems.isNotEmpty) ...[
            SizedBox(height: tokens.spaceSm),
            SpotifyThumbnail(
              item: post.spotifyMusicItems.first,
              originalUrl: post.urls
                  .firstWhere(
                    (u) => u.platform.toLowerCase().contains('spotify'),
                  )
                  .url,
            ),
          ],
          ..._linkListEntries(tokens, post),
          SizedBox(height: tokens.spaceMd),
          Row(
            children: [
              GestureDetector(
                onTap: onVote,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      post.hasVoted
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      size: 18,
                      color: post.hasVoted
                          ? tokens.primary
                          : tokens.textLow,
                    ),
                    SizedBox(width: tokens.spaceXs),
                    DesignText(
                      '${post.upvoteCount}',
                      style: DesignTextStyle.label,
                      color: post.hasVoted
                          ? tokens.primary
                          : tokens.textLow,
                    ),
                  ],
                ),
              ),
              SizedBox(width: tokens.spaceLg),
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: tokens.textLow,
              ),
              SizedBox(width: tokens.spaceXs),
              DesignText(
                '${post.commentCount}',
                style: DesignTextStyle.label,
                color: tokens.textLow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'music':
        return Icons.music_note_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'web':
        return Icons.language_rounded;
      default:
        return Icons.text_fields_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'music':
        return 'Musik';
      case 'video':
        return 'Video';
      case 'web':
        return 'Web';
      default:
        return 'Text';
    }
  }

  List<Widget> _linkListEntries(DesignTokens tokens, FeedPost post) {
    final links = post.type == 'video' || post.type == 'music'
        ? post.genericMusicUrls
        : post.type != 'web' && post.type != 'text'
            ? post.urls
            : const <MusicUrl>[];
    if (links.isEmpty) return const [];
    return [
      SizedBox(height: tokens.spaceSm),
      ...links.map(
        (url) => Padding(
          padding: EdgeInsets.only(bottom: tokens.spaceXs),
          child: Row(
            children: [
              Icon(Icons.link_rounded, size: 16, color: tokens.textLow),
              SizedBox(width: 6),
              Expanded(
                child: DesignText(
                  '${url.platform} – ${Uri.tryParse(url.url)?.host ?? url.url}',
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
