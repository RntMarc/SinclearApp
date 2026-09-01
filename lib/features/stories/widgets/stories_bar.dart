import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stories_for_flutter/stories_for_flutter.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../home/dashboard_controller.dart';
import '../models/stories_models.dart';
import '../services/stories_service.dart';
import 'story_create_sheet.dart';
import 'story_page.dart';
import 'story_viewer.dart';

const double _avatarSize = 56;
const double _ringPadding = 3;
const double _ringWidth = 2;
const double _circleOuter = _avatarSize + 2 * _ringPadding + 2 * _ringWidth;
const double _labelWidth = 68;
const double _barHeight = 96;

/// Horizontale Story-Kreisreihe oberhalb des Dashboards.
///
/// Registriert sich als [DashboardRefreshable] und rendert aus dem
/// sessionweiten Zustand des [StoriesService]: geladen wird einmal beim
/// App-Start, danach nur noch über den Dashboard-Zyklus (5-Minuten-Timer,
/// Pull-to-Refresh, App-Resume). Scrollen aus dem Sichtfeld löst dank
/// KeepAlive keinen Reload aus. Gesehene Stories werden sessionweit
/// vermerkt und idempotent an die API gemeldet.
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
    with AutomaticKeepAliveClientMixin
    implements DashboardRefreshable {
  /// Die Leiste bleibt beim Scrollen am Leben (wie die Dashboard-Widgets),
  /// damit sie nicht bei jedem Wiedereinblenden neu lädt. Die Daten selbst
  /// liegen sessionweit im [StoriesService].
  @override
  bool get wantKeepAlive => true;

  /// ID der im geöffneten Viewer aktuell sichtbaren Story (nur dort genutzt).
  final ValueNotifier<String?> _currentStory = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    widget.controller.register(this);
    widget.service.addListener(_onServiceChanged);
    if (widget.service.groups == null) refresh();
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChanged);
    widget.controller.unregister(this);
    _currentStory.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Future<void> refresh() {
    // Rate-Limit wie bei den Dashboard-Widgets: Im laufenden
    // refreshAll-Durchlauf oder nach Ablauf des Limits laden; ohne Daten
    // (erster App-Start) wird nie unterbunden. Aufgeschobene Läufe
    // übernimmt der Controller als Sammel-Refresh.
    final mayFetch =
        widget.controller.inRefreshPass ||
        widget.controller.claimRefreshPass() ||
        widget.service.groups == null;
    if (!mayFetch) return Future.value();
    return widget.service.refreshFeed();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tokens = DesignTheme.of(context);
    final groups = widget.service.groups;
    final error = widget.service.error;
    if (groups == null) {
      return error == null ? _buildSkeleton(tokens) : _buildError(tokens);
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
                (s) => !widget.service.isViewed(s.id),
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
            for (final story in group.stories)
              buildStoryPage(
                story: story,
                onShown: onShown,
                service: widget.service,
              ),
          ],
        ),
    ];
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
    final reportableById = <String, bool>{
      for (final group in groups)
        for (final story in group.stories) story.id: group.userId != ownId,
    };
    _currentStory.value = null;
    final items = _toStoryItems(groups, _onStoryShown);
    final storyIds = [
      for (final group in groups)
        for (final story in group.stories) story.id,
    ];
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewer(
          items: items,
          initialIndex: index,
          service: widget.service,
          currentStoryId: _currentStory,
          deletableById: deletableById,
          reportableById: reportableById,
          storyIds: storyIds,
          onDeleted: _onStoryDeleted,
          onReported: _onStoryReported,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _onStoryShown(String id) {
    unawaited(widget.service.markViewed(id));
    _markStoryNotificationRead(id);
    // Der Aufruf kommt aus initState einer Story-Seite (während des
    // Frame-Aufbaus); das Notifier-Update daher auf nach dem Frame schieben.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _currentStory.value = id;
    });
  }

  /// Markiert `story_post`-Benachrichtigungen der angesehenen Story als
  /// gelesen. Hält die Unread-Liste sauber, damit Story-Mengen nicht die
  /// 50er-Grenze sprengen und Forum-Unreads verdrängen.
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

  void _onStoryDeleted() {
    if (!mounted) return;
    refresh();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Story gelöscht')));
  }

  void _onStoryReported() {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Meldung gesendet')));
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
