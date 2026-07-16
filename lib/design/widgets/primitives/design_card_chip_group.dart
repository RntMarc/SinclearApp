import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import 'press_scale.dart';

/// An item displayed in a [DesignCardChipGroup].
class DesignCardChipItem {
  const DesignCardChipItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
}

/// Horizontal scrollable group of compact card-style chips.
///
/// Each item renders with card styling ([DesignTokens.surface] background,
/// [DesignTokens.surfaceShadow], [DesignTokens.radiusLg] border-radius, border)
/// but compact height and [DesignTextStyle.label] font — matching the
/// dimensions of a chip with the visual weight of a card.
///
/// Wenn [initialScrollIndex] gesetzt ist, scrollt die Gruppe beim ersten
/// Aufbau automatisch zu diesem Index, sodass das Item sichtbar wird.
class DesignCardChipGroup extends StatefulWidget {
  const DesignCardChipGroup({
    required this.items,
    this.initialScrollIndex,
    super.key,
  });

  final List<DesignCardChipItem> items;
  final int? initialScrollIndex;

  @override
  State<DesignCardChipGroup> createState() => _DesignCardChipGroupState();
}

class _DesignCardChipGroupState extends State<DesignCardChipGroup> {
  final _scrollController = ScrollController();
  final _itemKeys = <int, GlobalKey>{};
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scheduleScrollIfNeeded();
  }

  @override
  void didUpdateWidget(DesignCardChipGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialScrollIndex != oldWidget.initialScrollIndex) {
      _scrolled = false;
      _itemKeys.clear();
      _scheduleScrollIfNeeded();
    }
  }

  void _scheduleScrollIfNeeded() {
    if (widget.initialScrollIndex == null || _scrolled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToIndex());
  }

  void _scrollToIndex() {
    if (_scrolled) return;
    final index = widget.initialScrollIndex!;
    if (index >= widget.items.length) return;
    _scrolled = true;
    final key = _itemKeys[index];
    if (key?.currentContext == null) return;
    final ctx = key!.currentContext!;
    if (ctx.findRenderObject() == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.1,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return SizedBox(
      height: tokens.spaceLg * 3,
      child: ListView.separated(
        controller: _scrollController,
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
        separatorBuilder: (_, _) => SizedBox(width: tokens.spaceSm),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return _CardChip(
            key: _itemKeys.putIfAbsent(index, () => GlobalKey()),
            item: item,
          );
        },
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({super.key, required this.item});

  final DesignCardChipItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    final bg = item.selected ? tokens.primary : tokens.surface;
    final fg = item.selected ? tokens.textOnPrimary : tokens.textHigh;

    return PressScale(
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: item.selected
              ? null
              : Border.all(color: tokens.border.withValues(alpha: 0.5)),
          boxShadow: item.selected ? tokens.glowShadow : tokens.surfaceShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.icon,
              style: const TextStyle(
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(width: tokens.spaceXs),
            DesignText(
              item.label,
              style: DesignTextStyle.label,
              color: fg,
            ),
          ],
        ),
      ),
    );
  }
}
