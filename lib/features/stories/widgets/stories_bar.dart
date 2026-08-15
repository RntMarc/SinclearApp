import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stories_for_flutter/stories_for_flutter.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../../core/utils/base64_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../home/dashboard_controller.dart';
import '../models/stories_models.dart';
import '../services/stories_service.dart';
import 'story_create_sheet.dart';
import 'story_viewer.dart';

const double _avatarSize = 56;
const double _ringPadding = 3;
const double _ringWidth = 2;
const double _circleOuter = _avatarSize + 2 * _ringPadding + 2 * _ringWidth;
const double _labelWidth = 68;
const double _barHeight = 96;

/// Horizontale Story-Kreisreihe oberhalb des Dashboards.
///
/// Registriert sich als [DashboardRefreshable], damit Pull-to-Refresh und der
/// Auto-Refresh-Timer die Stories zusammen mit dem Dashboard aktualisieren.
/// Gesehene Stories werden lokal vermerkt und idempotent an die API gemeldet.
class StoriesBar extends StatefulWidget {
  const StoriesBar({
    required this.controller,
    required this.service,
    super.key,
  });

  final DashboardController controller;
  final StoriesService service;

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar>
    implements DashboardRefreshable {
  List<StoryFeedGroup>? _groups;
  Object? _error;
  final Set<String> _viewedIds = {};

  /// ID der im geöffneten Viewer aktuell sichtbaren Story (nur dort genutzt).
  final ValueNotifier<String?> _currentStory = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    widget.controller.register(this);
    refresh();
  }

  @override
  void dispose() {
    _currentStory.dispose();
    widget.controller.unregister(this);
    super.dispose();
  }

  @override
  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      final feed = await widget.service.feed();
      if (!mounted) return;
      setState(() {
        _groups = feed.data;
        _error = null;
        _viewedIds
          ..clear()
          ..addAll([
            for (final group in feed.data)
              for (final story in group.stories)
                if (story.viewed) story.id,
          ]);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _markViewed(String id) {
    if (!_viewedIds.add(id)) return;
    unawaited(_reportViewed(id));
  }

  Future<void> _reportViewed(String id) async {
    try {
      await widget.service.markViewed(id);
    } catch (_) {
      // Idempotent; der nächste Feed-Abruf liefert den Stand erneut.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final groups = _groups;
    if (groups == null) {
      return _error == null ? _buildSkeleton(tokens) : _buildError(tokens);
    }
    return SizedBox(
      height: _barHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
        children: [
          _AddStoryCircle(onTap: () => _createStory(context)),
          for (var i = 0; i < groups.length; i++)
            _StoryCircle(
              group: groups[i],
              unviewed: groups[i].stories.any(
                (s) => !_viewedIds.contains(s.id),
              ),
              onTap: () => _openViewer(context, groups, i),
            ),
        ],
      ),
    );
  }

  List<StoryItem> _toStoryItems(
    List<StoryFeedGroup> groups,
    ValueChanged<String> onShown,
  ) {
    return [
      for (final group in groups)
        StoryItem(
          name: group.displayName,
          thumbnail:
              resolveImageProvider(group.avatar) ??
              const AssetImage('assets/logo.png'),
          stories: [
            for (final story in group.stories) _storyScaffold(story, onShown),
          ],
        ),
    ];
  }

  Scaffold _storyScaffold(Story story, ValueChanged<String> onShown) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _ViewTracker(
        storyId: story.id,
        onShown: onShown,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _storyImage(story.image),
            if (story.caption != null && story.caption!.isNotEmpty)
              _captionOverlay(story.caption!),
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

  Future<void> _openViewer(
    BuildContext context,
    List<StoryFeedGroup> groups,
    int index,
  ) async {
    final scope = AppScope.of(context);
    final ownId = scope.auth.userId;
    final isAdmin = scope.auth.isAdmin;
    final deletableById = <String, bool>{
      for (final group in groups)
        for (final story in group.stories)
          story.id: isAdmin || group.userId == ownId,
    };
    _currentStory.value = null;
    final items = _toStoryItems(groups, _onStoryShown);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewer(
          items: items,
          initialIndex: index,
          service: widget.service,
          currentStoryId: _currentStory,
          deletableById: deletableById,
          onDeleted: _onStoryDeleted,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _onStoryShown(String id) {
    _markViewed(id);
    // Der Aufruf kommt aus initState einer Story-Seite (während des
    // Frame-Aufbaus); das Notifier-Update daher auf nach dem Frame schieben.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _currentStory.value = id;
    });
  }

  void _onStoryDeleted() {
    if (!mounted) return;
    refresh();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Story gelöscht')));
  }

  Future<void> _createStory(BuildContext context) async {
    final created = await showCreateStorySheet(context);
    if (created && mounted) refresh();
  }

  Widget _buildSkeleton(DesignTokens tokens) {
    return SizedBox(
      height: _barHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: EdgeInsets.only(right: tokens.spaceLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: _circleOuter,
                    height: _circleOuter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.surfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  Container(
                    width: _labelWidth,
                    height: 12,
                    decoration: BoxDecoration(
                      color: tokens.surfaceVariant.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(tokens.radiusSm),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(DesignTokens tokens) {
    return SizedBox(
      height: _barHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: tokens.danger),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: DesignText(
                'Stories konnten nicht geladen werden.',
                style: DesignTextStyle.label,
                color: tokens.textLow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DesignButton(
              variant: DesignButtonVariant.text,
              label: 'Erneut versuchen',
              onPressed: refresh,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  const _StoryCircle({
    required this.group,
    required this.unviewed,
    required this.onTap,
  });

  final StoryFeedGroup group;
  final bool unviewed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final ringColor = unviewed
        ? tokens.primary
        : tokens.textLow.withValues(alpha: 0.5);
    return Padding(
      padding: EdgeInsets.only(right: tokens.spaceLg),
      child: PressScale(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(_ringPadding),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: _ringWidth),
                boxShadow: unviewed ? tokens.glowShadow : null,
              ),
              child: _circleAvatar(group, tokens),
            ),
            SizedBox(height: tokens.spaceSm),
            SizedBox(
              width: _labelWidth,
              child: DesignText(
                group.displayName,
                style: DesignTextStyle.label,
                color: tokens.textHigh,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleAvatar(StoryFeedGroup group, DesignTokens tokens) {
    final provider = resolveImageProvider(group.avatar);
    if (provider != null) {
      return ClipOval(
        child: Image(
          image: provider,
          width: _avatarSize,
          height: _avatarSize,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initialsAvatar(group.displayName, tokens),
        ),
      );
    }
    return _initialsAvatar(group.displayName, tokens);
  }

  Widget _initialsAvatar(String name, DesignTokens tokens) {
    final initials = name.trim().isEmpty
        ? ''
        : name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      color: tokens.surfaceVariant,
      alignment: Alignment.center,
      child: DesignText(
        initials,
        style: DesignTextStyle.label,
        color: tokens.primary,
      ),
    );
  }
}

class _AddStoryCircle extends StatelessWidget {
  const _AddStoryCircle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(right: tokens.spaceLg),
      child: PressScale(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _circleOuter,
              height: _circleOuter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.surfaceVariant,
                border: Border.all(
                  color: tokens.border.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Icon(Icons.add_rounded, color: tokens.primary, size: 28),
            ),
            SizedBox(height: tokens.spaceSm),
            SizedBox(
              width: _labelWidth,
              child: DesignText(
                'Neu',
                style: DesignTextStyle.label,
                color: tokens.textHigh,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
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
