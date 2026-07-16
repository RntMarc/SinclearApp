import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/og_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';

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
    final tokens = DesignTheme.of(context);
    final host = Uri.tryParse(widget.url)?.host ?? widget.url;

    if (_loading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: tokens.surfaceVariant,
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: tokens.primary,
            ),
          ),
        ),
      );
    }

    final hasImage = _data?.imageUrl != null && _data!.imageUrl!.isNotEmpty;
    final hasTitle = _data?.title != null && _data!.title!.isNotEmpty;

    if (!hasImage && !hasTitle) {
      return _MinimalLinkCard(url: widget.url, host: host, tokens: tokens);
    }

    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(widget.url)),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: tokens.border.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    color: tokens.surfaceVariant,
                    child: Icon(Icons.language_rounded, size: 32, color: tokens.textLow),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceSm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTitle)
                      DesignText(
                        _data!.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTextStyle.label,
                        color: tokens.textHigh,
                      ),
                    if (_data?.description != null && _data!.description!.isNotEmpty) ...[
                      SizedBox(height: tokens.spaceXs),
                      DesignText(
                        _data!.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                      ),
                    ],
                    SizedBox(height: tokens.spaceXs),
                    Row(
                      children: [
                        Icon(Icons.language_rounded, size: 12, color: tokens.textLow),
                        SizedBox(width: tokens.spaceXs),
                        Expanded(
                          child: DesignText(
                            _data?.siteName ?? host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DesignTextStyle.label,
                            color: tokens.textLow,
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
  final DesignTokens tokens;

  const _MinimalLinkCard({
    required this.url,
    required this.host,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Container(
        padding: EdgeInsets.all(tokens.spaceSm),
        decoration: BoxDecoration(
          color: tokens.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
        child: Row(
          children: [
            Icon(Icons.open_in_new_rounded, size: 18, color: tokens.primary),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignText(
                    host,
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                  DesignText(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
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
