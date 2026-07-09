import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/og_helper.dart';

/// OpenGraph preview card for web links. Fetches OG metadata and displays
/// a compact card with image, title, description, and site name.
class OgPreviewCard extends StatefulWidget {
  final String url;

  const OgPreviewCard({super.key, required this.url});

  @override
  State<OgPreviewCard> createState() => _OgPreviewCardState();
}

class _OgPreviewCardState extends State<OgPreviewCard> {
  OgData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final data = await OgHelper.fetch(widget.url);
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final host = Uri.tryParse(widget.url)?.host ?? widget.url;

    if (_loading) {
      return Container(
        height: 100,
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

    final hasImage = _data?.imageUrl != null && _data!.imageUrl!.isNotEmpty;
    final hasTitle = _data?.title != null && _data!.title!.isNotEmpty;

    // If no OG data was found, show a minimal link card
    if (!hasImage && !hasTitle) {
      return _MinimalLinkCard(url: widget.url, host: host);
    }

    return InkWell(
      onTap: () => launchUrl(Uri.parse(widget.url)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (hasImage)
              SizedBox(
                width: 120,
                height: 100,
                child: CachedNetworkImage(
                  imageUrl: _data!.imageUrl!,
                  width: 120,
                  height: 100,
                  fit: BoxFit.cover,
                  errorWidget: (_, e, s) => Container(
                    width: 120,
                    height: 100,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.language_rounded, size: 32),
                  ),
                ),
              ),
            // Text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTitle)
                      Text(
                        _data!.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (_data?.description != null &&
                        _data!.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _data!.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.language_rounded,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _data?.siteName ?? host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalLinkCard extends StatelessWidget {
  final String url;
  final String host;

  const _MinimalLinkCard({required this.url, required this.host});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    host,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    );
  }
}
