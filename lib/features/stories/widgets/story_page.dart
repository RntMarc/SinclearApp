import 'package:flutter/material.dart';

import '../../../core/utils/base64_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../models/stories_models.dart';
import '../services/stories_service.dart';

/// Erstellt eine [Scaffold]-Seite für eine einzelne Story (Bild + Caption +
/// Zeitstempel + ViewCount) für die Anzeige im [FullPageView].
///
/// Meldet die Story-ID via [onShown], sobald die Seite angezeigt wird
/// (View-Markierung + Benachrichtigungs-Read). Ruft bei Bedarf die Detail-
/// API auf, um die ViewCount-Informationen zu laden.
Scaffold buildStoryPage({
  required Story story,
  required ValueChanged<String> onShown,
  StoriesService? service,
}) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: StoryPageBody(
      story: story,
      onShown: onShown,
      service: service,
    ),
  );
}

/// StatefulWidget für den Story-Inhalt, das den ViewCount nachlädt und im
/// Overlay anzeigt.
class StoryPageBody extends StatefulWidget {
  const StoryPageBody({
    required this.story,
    required this.onShown,
    this.service,
    super.key,
  });

  final Story story;
  final ValueChanged<String> onShown;
  final StoriesService? service;

  @override
  State<StoryPageBody> createState() => _StoryPageBodyState();
}

class _StoryPageBodyState extends State<StoryPageBody> {
  int? _viewCount;

  @override
  void initState() {
    super.initState();
    widget.onShown(widget.story.id);
    _loadViewCount();
  }

  Future<void> _loadViewCount() async {
    if (widget.service == null) return;
    try {
      final detail = await widget.service!.getStory(widget.story.id);
      if (!mounted) return;
      setState(() {
        _viewCount = detail.viewCount;
      });
    } catch (_) {
      // Silently ignore; viewCount is non-critical.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _storyImage(widget.story.image),
        _bottomOverlay(widget.story, _viewCount),
      ],
    );
  }
}

Widget _bottomOverlay(Story story, int? viewCount) {
  final caption = story.caption;
  return Align(
    alignment: Alignment.bottomLeft,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      decoration: (caption != null && caption.isNotEmpty) ||
              viewCount != null
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TimestampChip(createdAt: story.createdAt),
              if (viewCount != null && viewCount > 0) ...[
                const SizedBox(width: 8),
                _ViewCountChip(viewCount: viewCount),
              ],
            ],
          ),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
                shadows: [Shadow(blurRadius: 6, color: Colors.black)],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _storyImage(String image) {
  const fallback = Center(
    child: Icon(Icons.image_rounded, color: Colors.white38, size: 48),
  );
  try {
    final bytes = decodeBase64Image(image);
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => fallback,
    );
  } catch (_) {
    return fallback;
  }
}

class _TimestampChip extends StatelessWidget {
  const _TimestampChip({required this.createdAt});

  final String createdAt;

  @override
  Widget build(BuildContext context) {
    final label = formatRelativeDayTime(createdAt);
    return Semantics(
      label: 'Gepostet $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.4,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
      ),
    );
  }
}

class _ViewCountChip extends StatelessWidget {
  const _ViewCountChip({required this.viewCount});

  final int viewCount;

  @override
  Widget build(BuildContext context) {
    final label = viewCount == 1 ? '1 Ansicht' : '$viewCount Ansichten';
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.remove_red_eye_rounded, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.4,
                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
