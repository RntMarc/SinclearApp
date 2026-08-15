import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stories_for_flutter/stories_for_flutter.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../../core/utils/base64_helper.dart';
import '../../moderation/models/moderation_models.dart';
import '../../moderation/widgets/moderation_request_sheet.dart';
import '../models/stories_models.dart';
import '../services/stories_service.dart';
import '../widgets/story_viewer.dart';

/// Öffnet den Story-Viewer für eine bestimmte Story-ID, wie sie aus
/// Benachrichtigungs-Tiefenlinks kommt. Die Screen lädt den Feed, findet
/// die zugehörige Story und zeigt den Viewer an. Beim Schließen wird
/// der Screen automatisch entfernt.
class StoryDeepLinkScreen extends StatefulWidget {
  const StoryDeepLinkScreen({required this.storyId, super.key});

  final String storyId;

  @override
  State<StoryDeepLinkScreen> createState() => _StoryDeepLinkScreenState();
}

class _StoryDeepLinkScreenState extends State<StoryDeepLinkScreen> {
  bool _loading = true;
  String? _error;
  final ValueNotifier<String?> _currentStory = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _loadAndOpen();
  }

  @override
  void dispose() {
    _currentStory.dispose();
    super.dispose();
  }

  Future<void> _loadAndOpen() async {
    final scope = AppScope.of(context);
    final service = scope.stories;
    final ownId = scope.auth.userId;
    final isAdmin = scope.auth.isAdmin;

    try {
      final feed = await service.feed();
      if (!mounted) return;

      // Gruppe und Story-Index finden.
      int groupIndex = -1;
      int storyIndex = -1;
      for (var g = 0; g < feed.data.length; g++) {
        for (var s = 0; s < feed.data[g].stories.length; s++) {
          if (feed.data[g].stories[s].id == widget.storyId) {
            groupIndex = g;
            storyIndex = s;
            break;
          }
        }
        if (groupIndex >= 0) break;
      }

      if (groupIndex < 0) {
        setState(() {
          _loading = false;
          _error = 'Story nicht gefunden.';
        });
        return;
      }

      final groups = feed.data;
      final deletableById = <String, bool>{
        for (final group in groups)
          for (final story in group.stories)
            story.id: isAdmin || group.userId == ownId,
      };
      final reportableById = <String, bool>{
        for (final group in groups)
          for (final story in group.stories) story.id: group.userId != ownId,
      };

      final items = _toStoryItems(groups);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StoryViewer(
            items: items,
            initialIndex: groupIndex,
            service: service,
            currentStoryId: _currentStory,
            deletableById: deletableById,
            reportableById: reportableById,
            onDeleted: () {
              if (mounted) Navigator.of(context).pop();
            },
            onReported: () {
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Story konnte nicht geladen werden.';
      });
    }
  }

  List<StoryItem> _toStoryItems(List<StoryFeedGroup> groups) {
    return [
      for (final group in groups)
        StoryItem(
          name: group.displayName,
          thumbnail:
              resolveImageProvider(group.avatar) ??
              const AssetImage('assets/logo.png'),
          stories: [
            for (final story in group.stories) _storyScaffold(story),
          ],
        ),
    ];
  }

  Scaffold _storyScaffold(Story story) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _storyImage(story.image),
          if (story.caption != null && story.caption!.isNotEmpty)
            _captionOverlay(story.caption!),
        ],
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
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    } catch (_) {
      return fallback;
    }
  }

  Widget _captionOverlay(String caption) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black87],
          ),
        ),
        child: Text(
          caption,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.4,
            shadows: [Shadow(blurRadius: 6, color: Colors.black)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unbekannter Fehler',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zurück'),
            ),
          ],
        ),
      ),
    );
  }
}
