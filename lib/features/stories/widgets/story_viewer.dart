import 'package:flutter/material.dart';

import '../../moderation/models/moderation_models.dart';
import '../../moderation/widgets/moderation_request_sheet.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../models/stories_models.dart';
import '../services/stories_service.dart';
import 'story_viewers_sheet.dart';

/// Eigener Vollbild-Viewer mit eigenem [PageView]. Timeline, Nutzername und Buttons werden in einem einzigen
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

  /// Reaktionen je Story-ID (neueste zuerst), beim Anzeigen geladen.
  final Map<String, List<StoryReaction>> _reactionsByStory = {};

  /// Ob die vertikale Emoji-Auswahl über dem Reaktions-Button offen ist.
  bool _pickerOpen = false;
  bool _reactionBusy = false;

  @override
  void initState() {
    super.initState();
    _pages = widget.items.expand((item) => item.stories).toList();
    final initialPage = _pageIndexForGroup(widget.initialIndex);
    _pageController = PageController(initialPage: initialPage);
    _currentPage = initialPage;
    _loadReactions(widget.storyIds[initialPage]);
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
    } else {
      _close();
    }
  }

  void _onPageChanged(int page) {
    if (page == _pages.length) {
      _close();
      return;
    }
    setState(() {
      _currentPage = page;
      _pickerOpen = false;
    });
    _loadReactions(widget.storyIds[page]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.currentStoryId.value = widget.storyIds[page];
    });
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

  bool _isReportable(String storyId) => widget.reportableById[storyId] ?? false;

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
  // Reactions
  // ---------------------------------------------------------------------------

  /// Nur fremde Stories dürfen reagiert werden (Ersteller ausgeschlossen).
  /// `_isReportable` ist exakt „nicht eigener Autor“.
  bool _canReact(String storyId) => _isReportable(storyId);

  Future<void> _loadReactions(String storyId) async {
    try {
      final reactions = await widget.service.getReactions(storyId);
      if (!mounted) return;
      setState(() => _reactionsByStory[storyId] = reactions);
    } catch (_) {
      // Reaktionen sind nicht kritisch; alte Daten bleiben sichtbar.
    }
  }

  Future<void> _toggleReaction(String storyId, String emoji) async {
    if (_reactionBusy) return;
    final userId = AppScope.of(context).auth.userId;
    final current = _reactionsByStory[storyId] ?? const <StoryReaction>[];
    StoryReaction? mine;
    for (final reaction in current) {
      if (reaction.isMine(userId)) {
        mine = reaction;
        break;
      }
    }

    setState(() => _reactionBusy = true);
    try {
      final updated = mine?.emoji == emoji
          ? await widget.service.removeReaction(storyId)
          : await widget.service.react(storyId, emoji);
      if (!mounted) return;
      setState(() {
        _reactionsByStory[storyId] = updated;
        _pickerOpen = false;
        _reactionBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _reactionBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reaktion fehlgeschlagen. Bitte erneut versuchen.'),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final storyId = widget.storyIds[_currentPage];
    final groupIndex = _groupIndexForPage(_currentPage);
    final userId = AppScope.of(context).auth.userId;
    final canReact = _canReact(storyId);
    final reactions = _reactionsByStory[storyId] ?? const <StoryReaction>[];
    String? selectedEmoji;
    for (final reaction in reactions) {
      if (reaction.isMine(userId)) {
        selectedEmoji = reaction.emoji;
        break;
      }
    }

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
              itemCount: _pages.length + 1,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                if (index >= _pages.length) return const SizedBox.expand();
                return _pages[index];
              },
            ),

            // Tap zones: left third = prev, right two-thirds = next
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _canGoBack ? _goBack : null,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _goForward,
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
                      if (!_isReportable(storyId)) const SizedBox(width: 8),
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

            // Bottom-left: reaction button, picker and reactions bar
            if (canReact || reactions.isNotEmpty)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      bottom: 24,
                      right: _isDeletable(storyId) ? 72 : 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_pickerOpen && canReact) ...[
                          _ReactionPicker(
                            selectedEmoji: selectedEmoji,
                            busy: _reactionBusy,
                            onSelect: (emoji) =>
                                _toggleReaction(storyId, emoji),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (canReact)
                              _ReactionButton(
                                active: _pickerOpen,
                                onTap: _reactionBusy
                                    ? null
                                    : () => setState(
                                        () => _pickerOpen = !_pickerOpen,
                                      ),
                              ),
                            if (canReact && reactions.isNotEmpty)
                              const SizedBox(width: 8),
                            if (reactions.isNotEmpty)
                              Flexible(
                                child: _ReactionRow(reactions: reactions),
                              ),
                          ],
                        ),
                      ],
                    ),
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
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
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

// =============================================================================
// Story reactions
// =============================================================================

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.onTap, required this.active});

  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Reaktion auswählen',
      button: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.55),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Icon(
            Icons.add_reaction_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Vertikale Emoji-Auswahl, die über dem Reaktions-Button aufklappt.
class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({
    required this.selectedEmoji,
    required this.busy,
    required this.onSelect,
  });

  final String? selectedEmoji;
  final bool busy;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final emoji in kStoryReactionEmojis)
                _ReactionPickerItem(
                  emoji: emoji,
                  selected: emoji == selectedEmoji,
                  onTap: busy ? null : () => onSelect(emoji),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionPickerItem extends StatelessWidget {
  const _ReactionPickerItem({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mit $emoji reagieren',
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.symmetric(vertical: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? Colors.white.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}

/// Horizontale Leiste der Reaktionen: Profilbild mit darüber gelagertem,
/// leicht gekipptem Emoji. Bei Überlauf horizontal scrollbar.
class _ReactionRow extends StatelessWidget {
  const _ReactionRow({required this.reactions});

  final List<StoryReaction> reactions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: reactions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final reaction = reactions[index];
          final name = reaction.displayName.trim().isEmpty
              ? 'Unbekannt'
              : reaction.displayName;
          return Semantics(
            label: '${reaction.emoji} von $name',
            child: Center(
              child: SizedBox(
                width: 34,
                height: 34,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DesignAvatar(
                      imageUrl: reaction.avatar,
                      name: reaction.displayName,
                      size: 30,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Transform.rotate(
                        angle: -0.35,
                        child: Text(
                          reaction.emoji,
                          style: const TextStyle(
                            fontSize: 14,
                            shadows: [
                              Shadow(blurRadius: 3, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
