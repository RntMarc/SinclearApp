import 'package:flutter/material.dart';
import 'package:stories_for_flutter/full_page_view.dart';
import 'package:stories_for_flutter/stories_for_flutter.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../services/stories_service.dart';

/// Vollbild-Viewer aus dem Paket, ergänzt um einen Löschen-Knopf.
///
/// `FullPageView` ist ein geschlossenes Widget; eigene Bedienelemente lassen
/// sich nur DARÜBER legen. Der Mülleimer schwebt daher rechts oben über dem
/// Viewer und ist nur sichtbar, wenn der Nutzer die aktuell angezeigte Story
/// löschen darf (eigene Story oder Admin). Vor dem Löschen wird nachgefragt.
class StoryViewer extends StatefulWidget {
  const StoryViewer({
    required this.items,
    required this.initialIndex,
    required this.service,
    required this.currentStoryId,
    required this.deletableById,
    required this.onDeleted,
    super.key,
  });

  final List<StoryItem> items;
  final int initialIndex;
  final StoriesService service;

  /// ID der aktuell sichtbaren Story; wird von den Story-Seiten gemeldet.
  final ValueNotifier<String?> currentStoryId;

  /// Story-ID → darf der aktuelle Nutzer diese Story löschen?
  final Map<String, bool> deletableById;

  /// Wird nach erfolgreichem Löschen aufgerufen (der Viewer hat sich
  /// dann bereits geschlossen).
  final VoidCallback onDeleted;

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  bool _deleting = false;

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
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      await widget.service.delete(storyId);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onDeleted();
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story konnte nicht gelöscht werden.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Stack(
      children: [
        FullPageView(
          storiesMapList: widget.items,
          storyNumber: widget.initialIndex,
          fullpageVisitedColor: tokens.primary,
        ),
        SafeArea(
          child: ValueListenableBuilder<String?>(
            valueListenable: widget.currentStoryId,
            builder: (context, storyId, _) {
              if (storyId == null ||
                  !(widget.deletableById[storyId] ?? false)) {
                return const SizedBox.shrink();
              }
              return Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 48, right: 16),
                  child: Semantics(
                    label: 'Story löschen',
                    button: true,
                    child: PressScale(
                      onTap: _deleting ? null : () => _confirmDelete(storyId),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: _deleting
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
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
