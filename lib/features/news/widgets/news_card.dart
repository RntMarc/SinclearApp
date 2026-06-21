import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/cache/image_cache_manager.dart';
import '../../../../core/di/app_scope.dart';
import '../models/news_models.dart';
import '../services/favicon_service.dart';

class NewsCard extends StatelessWidget {
  final NewsItem item;
  final bool voted;
  final bool showVoteButton;
  final VoidCallback? onToggleVote;

  const NewsCard({
    super.key,
    required this.item,
    required this.voted,
    this.showVoteButton = true,
    this.onToggleVote,
  });

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = _formatDate(item.date);
    final news = AppScope.of(context).news;
    final faviconService = FaviconService();
    final rawFaviconUrl =
        item.sourceIcon ?? faviconService.resolveFaviconUrl(item.url);
    final faviconUrl = rawFaviconUrl.isNotEmpty
        ? news.proxyImageUrl(rawFaviconUrl, type: 'favicon')
        : '';
    final imageUrl = item.imageUrl != null
        ? news.proxyImageUrl(item.imageUrl!, type: 'preview')
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final uri = Uri.tryParse(item.url);
          if (uri != null) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageArea(theme, imageUrl, faviconUrl),
            _buildTextArea(theme, dateStr),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea(ThemeData theme, String? imageUrl, String faviconUrl) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(theme, imageUrl),
          _buildSourceBadge(theme, faviconUrl),
          if (showVoteButton && onToggleVote != null) _buildVoteButton(theme),
        ],
      ),
    );
  }

  Widget _buildImage(ThemeData theme, String? imageUrl) {
    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        cacheManager: ImageCacheManager.previewCache,
        fit: BoxFit.cover,
        placeholder: (_, _) => _buildImagePlaceholder(theme, null),
        errorWidget: (_, _, _) =>
            _buildImagePlaceholder(theme, Icons.broken_image_outlined),
      );
    }
    return _buildImagePlaceholder(theme, Icons.article_outlined);
  }

  Widget _buildImagePlaceholder(ThemeData theme, IconData? icon) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          icon ?? Icons.article_outlined,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildSourceBadge(ThemeData theme, String faviconUrl) {
    return Positioned(
      left: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (faviconUrl.isNotEmpty)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: faviconUrl,
                  cacheManager: ImageCacheManager.faviconCache,
                  width: 14,
                  height: 14,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const SizedBox(width: 14, height: 14),
                  errorWidget: (_, _, _) =>
                      const SizedBox(width: 14, height: 14),
                ),
              )
            else
              Icon(
                Icons.rss_feed_rounded,
                size: 14,
                color: theme.colorScheme.primary,
              ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                item.sourceName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteButton(ThemeData theme) {
    return Positioned(
      right: 4,
      top: 4,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onToggleVote,
            icon: Icon(
              voted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
            ),
            color: voted ? Colors.red : theme.colorScheme.onSurfaceVariant,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea(ThemeData theme, String dateStr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            dateStr,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
