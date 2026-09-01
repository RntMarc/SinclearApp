import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stories_for_flutter/stories_for_flutter.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
import '../models/stories_models.dart';
import '../services/stories_service.dart';
import '../widgets/story_page.dart';
import '../widgets/story_viewer.dart';

/// Öffnet den Story-Viewer für eine bestimmte Story-ID, wie sie aus
/// Benachrichtigungs-Tiefenlinks kommt.
///
/// Die Screen lädt den Feed, findet die zugehörige Story-Gruppe und zeigt
/// den Viewer an. Beim Schließen (Story durchgespielt, Löschen, Melden oder
/// System-Back) springt die App zurück auf das Dashboard. Die Screen selbst
/// ist nur eine unsichtbare Zwischenstation ohne eigene Navigation.
class StoryDeepLinkScreen extends StatefulWidget {
  const StoryDeepLinkScreen({required this.storyId, super.key});

  final String storyId;

  @override
  State<StoryDeepLinkScreen> createState() => _StoryDeepLinkScreenState();
}

class _StoryDeepLinkScreenState extends State<StoryDeepLinkScreen> {
  bool _started = false;
  bool _loading = true;
  String? _error;
  StoriesService? _service;

  /// ID der im geöffneten Viewer aktuell sichtbaren Story (für die
  /// Löschen-/Melden-Buttons im Viewer).
  final ValueNotifier<String?> _currentStory = ValueNotifier<String?>(null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _openStory();
  }

  @override
  void dispose() {
    _currentStory.dispose();
    super.dispose();
  }

  Future<void> _openStory() async {
    final scope = AppScope.of(context);
    final service = scope.stories;
    _service = service;
    final ownId = scope.auth.userId;
    final isAdmin = scope.auth.isAdmin;

    List<StoryFeedGroup> groups;
    try {
      groups = (await service.feed()).data;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Story konnte nicht geladen werden.';
      });
      return;
    }

    // Gruppe finden, die die gesuchte Story enthält. Der Viewer startet —
    // wie beim manuellen Antippen — am Anfang der Gruppe.
    int groupIndex = -1;
    for (var g = 0; g < groups.length; g++) {
      if (groups[g].stories.any((s) => s.id == widget.storyId)) {
        groupIndex = g;
        break;
      }
    }

    if (!mounted) return;

    if (groupIndex < 0) {
      setState(() {
        _loading = false;
        _error = 'Story nicht gefunden.';
      });
      return;
    }

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
    final storyIds = [
      for (final group in groups)
        for (final story in group.stories) story.id,
    ];

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
          storyIds: storyIds,
          onDeleted: () {},
          onReported: () {},
        ),
      ),
    );

    // Der Viewer hat sich geschlossen. Diese Screen liegt bei einem
    // Benachrichtigungs-Tap als einzige GoRouter-Seite im Stack — ein
    // imperatives `pop()` ließe einen leeren Navigator zurück. Daher
    // explizit zum Dashboard wechseln.
    _goHome();
  }

  void _goHome() {
    if (!mounted) return;
    context.go('/home');
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
            for (final story in group.stories)
              buildStoryPage(
                story: story,
                onShown: _onStoryShown,
                service: _service,
              ),
          ],
        ),
    ];
  }

  void _onStoryShown(String id) {
    unawaited(_service?.markViewed(id));
    _markStoryNotificationRead(id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _currentStory.value = id;
    });
  }

  /// Markiert `story_post`-Benachrichtigungen der angesehenen Story als
  /// gelesen (analog zu `stories_bar.dart`).
  void _markStoryNotificationRead(String id) {
    final scope = AppScope.of(context);
    unawaited(() async {
      try {
        final ids = scope.notification.unreadIdsForStory(id);
        if (ids.isEmpty) return;
        final token = await scope.auth.getAccessToken();
        await scope.notification.markRead(ids, token: token);
      } catch (_) {
        // Idempotent; der nächste Abruf liefert den Stand erneut.
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
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
            TextButton(onPressed: _goHome, child: const Text('Zum Dashboard')),
          ],
        ),
      ),
    );
  }
}
