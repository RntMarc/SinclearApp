import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/url_helper.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../models/photo_models.dart';

/// Vollbild-Viewer für Fotos (analog zum Story-Viewer).
///
/// Horizontal wischbar durch alle geladenen Fotos; zeigt unten den
/// Sinclear-Autor und die Unsplash-Attribution (Fotograf + Link).
class PhotoViewer extends StatefulWidget {
  final List<Photo> photos;
  final int initialIndex;

  const PhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _FullPhoto(widget.photos[i]),
            ),
            const Positioned(top: 8, right: 8, child: _CloseButton()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PhotoCredit(photo: widget.photos[_index]),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullPhoto extends StatelessWidget {
  final Photo photo;

  const _FullPhoto(this.photo);

  @override
  Widget build(BuildContext context) {
    if (photo.regular == null) {
      return const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.white38,
          size: 48,
        ),
      );
    }
    return InteractiveViewer(
      maxScale: 4,
      child: CachedNetworkImage(
        imageUrl: photo.regular!,
        fit: BoxFit.contain,
        placeholder: (_, _) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorWidget: (_, _, _) => const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: Colors.white38,
            size: 48,
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Schließen',
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _PhotoCredit extends StatelessWidget {
  final Photo photo;

  const _PhotoCredit({required this.photo});

  @override
  Widget build(BuildContext context) {
    final author = photo.author.displayName;
    final photographer = photo.photographer.displayName;
    final photographerUrl = photo.photographer.url;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black87],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (author != null)
            DesignText(
              author,
              style: DesignTextStyle.body,
              color: Colors.white,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (photographer != null) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: photographerUrl == null
                  ? null
                  : () => launchExternalUrl(photographerUrl),
              child: DesignText(
                photographerUrl == null
                    ? 'Foto: $photographer'
                    : 'Foto: $photographer · Unsplash',
                style: DesignTextStyle.label,
                color: Colors.white70,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
