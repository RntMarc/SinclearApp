import 'package:flutter/material.dart';

import '../../../core/utils/base64_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../models/stories_models.dart';

/// Erstellt eine [Scaffold]-Seite für eine einzelne Story (Bild + Caption +
/// Zeitstempel) für die Anzeige im [FullPageView].
///
/// Meldet die Story-ID via [onShown], sobald die Seite angezeigt wird
/// (View-Markierung + Benachrichtigungs-Read).
Scaffold buildStoryPage({
  required Story story,
  required ValueChanged<String> onShown,
}) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: _ViewTracker(
      storyId: story.id,
      onShown: onShown,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _storyImage(story.image),
          _bottomOverlay(story),
        ],
      ),
    ),
  );
}

Widget _bottomOverlay(Story story) {
  final caption = story.caption;
  return Align(
    alignment: Alignment.bottomLeft,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      decoration: (caption != null && caption.isNotEmpty)
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
          _TimestampChip(createdAt: story.createdAt),
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

class _ViewTracker extends StatefulWidget {
  const _ViewTracker({
    required this.storyId,
    required this.onShown,
    required this.child,
  });

  final String storyId;
  final ValueChanged<String> onShown;
  final Widget child;

  @override
  State<_ViewTracker> createState() => _ViewTrackerState();
}

class _ViewTrackerState extends State<_ViewTracker> {
  @override
  void initState() {
    super.initState();
    widget.onShown(widget.storyId);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
