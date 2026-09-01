import 'package:flutter/material.dart';
import 'package:stories_for_flutter/stories_for_flutter.dart';

import '../../moderation/models/moderation_models.dart';
import '../../moderation/widgets/moderation_request_sheet.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../services/stories_service.dart';
import 'story_viewers_sheet.dart';

/// Eigener Vollbild-Viewer mit eigenem [PageView] statt des paket-internen
/// [FullPageView]. Timeline, Nutzername und Buttons werden in einem einzigen
/// [SafeArea]-Header am oberen Bildschirmrand verankert.
class StoryViewer extends StatefulWidget {
  const StoryViewer({
    required this.items,
    required this.initialIndex,
    required this.service,
    required this.currentStoryId,
    required this.deletableById,
    required this.reportableById,
    required this.storyIds,
    required this.onDeleted,
    required this.onReported,
    super.key,
  });

  final List<StoryItem> items;
  final int initialIndex;
  final StoriesService service;
  final ValueNotifier<String?> currentStoryId;
  final Map<String, bool> deletableById;
  final Map<String, bool> reportableById;
  final List<String> storyIds;
  final VoidCallback onDeleted;
  final VoidCallback onReported;

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late final PageController _pageController;
  late final List<Widget> _pages;
  int _currentPage = 0;
  bool _busy = false;
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _pages = widget.items.expand((item) => item.stories).toList();
    final initialPage = _pageIndexForGroup(widget.initialIndex);
    _pageController = PageController(initialPage: initialPage);
    _currentPage = initialPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.currentStoryId.value = widget.storyIds[initialPage];
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  int _pageIndexForGroup(int groupIndex) {
    var offset = 0;
    for (var i = 0; i < groupIndex; i++) {
      offset += widget.items[i].stories.length;
    }
    return offset;
  }

  int _groupIndexForPage(int page) {
    var offset = 0;
    for (var i = 0; i < widget.items.length; i++) {
      offset += widget.items[i].stories.length;
      if (page < offset) return i;
    }
    return widget.items.length - 1;
  }

  bool get _canGoBack => _currentPage > 0;
  bool get _canGoForward => _currentPage < _pages.length - 1;

  void _goBack() {
    if (_canGoBack) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goForward() {
    if (_canGoForward) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.currentStoryId.value = widget.storyIds[page];
    });
    if (page == _pages.length - 1) _close();
  }

  // ---------------------------------------------------------------------------
  // Gestures
  // ---------------------------------------------------------------------------

  void _close() => Navigator.of(context).pop();

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.delta.dy;
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final fling = (details.primaryVelocity ?? 0) > 400;
    final dragged = _dragDistance > 100;
    _dragDistance = 0;
    if (dragged || fling) _close();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  bool _isDeletable(String storyId) => widget.deletableById[storyId] ?? false;

  bool _isReportable(String storyId) =>
      widget.reportableById[storyId] ?? false;

  void _showViewers(String storyId) {
    showStoryViewersSheet(context, storyId: storyId, service: widget.service);
  }

  Future<void> _confirmDelete(String storyId) async {
    final tokens = DesignTheme.of(context);
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            'Story löschen?',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Die Story wird dauerhaft entfernt.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceLg),
          Row(
            children: [
              Expanded(
                child: DesignButton(
                  variant: DesignButtonVariant.outlined,
                  label: 'Abbrechen',
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: DesignButton(
                  variant: DesignButtonVariant.filled,
                  label: 'Löschen',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _delete(storyId);
  }

  Future<void> _delete(String storyId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.service.delete(storyId);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDeleted();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story konnte nicht gelöscht werden.')),
      );
    }
  }

  Future<void> _report(String storyId) async {
    if (_busy) return;
    final isOwn = !_isReportable(storyId);
    final submitted = await showModerationRequestSheet(
      context,
      objectType: ModerationObjectType.story,
      objectId: storyId,
      objectName: 'Story',
      isOwn: isOwn,
      supportedTypes: isOwn
          ? [ModerationRequestType.other]
          : [ModerationRequestType.report, ModerationRequestType.other],
    );
    if (!submitted || !mounted) return;
    Navigator.of(context).pop();
    widget.onReported();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final storyId = widget.storyIds[_currentPage];
    final groupIndex = _groupIndexForPage(_currentPage);
    final group = widget.items[groupIndex];

    return Container(
      color: Colors.black,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onVerticalDragCancel: () => _dragDistance = 0,
        child: Stack(
          children: [
            // Story pages
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) => _pages[index],
            ),

            // Tap zones: left third = prev, right two-thirds = next
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: InkWell(
                      onTap: _canGoBack ? _goBack : null,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _canGoForward ? _goForward : null,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),

            // Top header: gradient + timeline + name
            SafeArea(
              bottom: false,
              child: _HeaderOverlay(
                currentPage: _currentPage,
                groupIndex: groupIndex,
                items: widget.items,
              ),
            ),

            // Top-right action buttons
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 48, right: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isReportable(storyId))
                        _ViewersButton(
                          onTap: _busy ? null : () => _showViewers(storyId),
                        ),
                      if (!_isReportable(storyId))
                        const SizedBox(width: 8),
                      _ReportButton(
                        onTap: _busy ? null : () => _report(storyId),
                      ),
                      const SizedBox(width: 8),
                      _CloseButton(onTap: _close),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom-right delete button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24, right: 16),
                  child: _isDeletable(storyId)
                      ? _DeleteButton(
                          onTap: _busy ? null : () => _confirmDelete(storyId),
                          busy: _busy,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Header overlay (gradient + timeline + name)
// =============================================================================

class _HeaderOverlay extends StatelessWidget {
  const _HeaderOverlay({
    required this.currentPage,
    required this.groupIndex,
    required this.items,
  });

  final int currentPage;
  final int groupIndex;
  final List<StoryItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gradient background covering timeline + name
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timeline progress bars
              _TimelineBar(
                currentPage: currentPage,
                groupIndex: groupIndex,
                items: items,
              ),
              // User name + avatar row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image(
                        image: items[groupIndex].thumbnail,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        items[groupIndex].name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Timeline progress bars
// =============================================================================

class _TimelineBar extends StatelessWidget {
  const _TimelineBar({
    required this.currentPage,
    required this.groupIndex,
    required this.items,
  });

  final int currentPage;
  final int groupIndex;
  final List<StoryItem> items;

  @override
  Widget build(BuildContext context) {
    final group = items[groupIndex];
    final totalInGroup = group.stories.length;
    final groupStart = _groupStartIndex(groupIndex);
    final progress = currentPage - groupStart + 1; // 1-indexed progress

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: List.generate(totalInGroup, (index) {
          final completed = index < progress;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  color: completed ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  int _groupStartIndex(int gi) {
    var offset = 0;
    for (var i = 0; i < gi; i++) {
      offset += items[i].stories.length;
    }
    return offset;
  }
}

// =============================================================================
// Reusable button widgets
// =============================================================================

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Story schließen',
      button: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap, required this.busy});

  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Story löschen',
      button: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
        ),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Story melden',
      button: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ViewersButton extends StatelessWidget {
  const _ViewersButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Zuschauer anzeigen',
      button: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Icon(
            Icons.people_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
