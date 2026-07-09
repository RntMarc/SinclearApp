import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../core/utils/spotify_helper.dart';
import '../../../core/widgets/user_avatar.dart';
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
    final theme = Theme.of(context);
    final typeIcon = _typeIcon(post.type);
    final typeLabel = _typeLabel(post.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  UserAvatar(
                    imageUrl: post.userImage,
                    displayName: post.userName ?? post.userId,
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName ?? 'Benutzer',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          app_date.formatRelativeDate(post.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    typeIcon,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    typeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (post.userId == currentUserId && onDelete != null)
                    PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Löschen',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (v) {
                        if (v == 'delete') onDelete!();
                      },
                    ),
                ],
              ),
              if (post.title != null && post.title!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  post.title!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (post.text != null && post.text!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  post.text!,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
              // --- Native embed thumbnails ---
              if (post.type == 'web') ...[
                if (post.youtubeIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  YouTubeThumbnail(videoId: post.youtubeIds.first),
                ],
                if (post.spotifyItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SpotifyThumbnail(
                    item: post.spotifyItems.first,
                    originalUrl: post.webUrls.firstWhere(
                      (u) => SpotifyHelper.parseUrl(u) != null,
                      orElse: () => post.webUrls.first,
                    ),
                  ),
                ],
                if (post.genericUrls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  OgPreviewCard(url: post.genericUrls.first),
                ],
              ],
              if (post.type == 'video' && post.youtubeVideoIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                YouTubeThumbnail(videoId: post.youtubeVideoIds.first),
              ],
              if (post.type == 'music' && post.spotifyMusicItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                SpotifyThumbnail(
                  item: post.spotifyMusicItems.first,
                  originalUrl: post.urls
                      .firstWhere(
                        (u) => u.platform.toLowerCase().contains('spotify'),
                      )
                      .url,
                ),
              ],
              // --- Link list for remaining (non-embed) URLs ---
              ..._linkListEntries(context, post),
              const SizedBox(height: 12),
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
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.upvoteCount}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: post.hasVoted
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  /// Returns link list widgets for URLs that are not shown as native embeds.
  List<Widget> _linkListEntries(BuildContext context, FeedPost post) {
    final theme = Theme.of(context);
    final links = post.type == 'video' || post.type == 'music'
        ? post.genericMusicUrls
        : post.type != 'web' && post.type != 'text'
            ? post.urls
            : const <MusicUrl>[];
    if (links.isEmpty) return const [];
    return [
      const SizedBox(height: 8),
      ...links.map(
        (url) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.link_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${url.platform} – ${Uri.tryParse(url.url)?.host ?? url.url}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
