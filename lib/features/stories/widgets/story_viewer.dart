import 'package:flutter/material.dart';
import 'package:stories_for_flutter/full_page_view.dart';
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

/// Vollbild-Viewer aus dem Paket, ergänzt um Schließen-, Melden-,
/// Löschen- und Zuschauer-Button.
///
/// `FullPageView` ist ein geschlossenes Widget; eigene Bedienelemente lassen
/// sich nur DARÜBER legen. Oben rechts liegen der X-Button zum Schließen
/// (zusätzlich schließt eine Wischgeste nach unten), die Flag zum Melden
/// und — nur beim eigenen Story-Autor oder Admin — der Personen-Button
/// zum Anzeigen der Zuschauer-Liste. Unten rechts liegt der Löschen-Button
/// (eigene Story oder Admin); er zeigt vor dem Ausführen eine Bestätigung an.
class StoryViewer extends StatefulWidget {
  const StoryViewer({
    required this.items,
    required this.initialIndex,
    required this.service,
    required this.currentStoryId,
    required this.deletableById,
    required this.reportableById,
    required this.onDeleted,
    required this.onReported,
    super.key,
  });

  final List<StoryItem> items;
  final int initialIndex;
  final StoriesService service;

  /// ID der aktuell sichtbaren Story; wird von den Story-Seiten gemeldet.
  final ValueNotifier<String?> currentStoryId;

  /// Story-ID → darf der aktuelle Nutzer diese Story löschen?
  final Map<String, bool> deletableById;

  /// Story-ID → darf der aktuelle Nutzer diese Story melden?
  final Map<String, bool> reportableById;

  /// Wird nach erfolgreichem Löschen aufgerufen (der Viewer hat sich
  /// dann bereits geschlossen).
  final VoidCallback onDeleted;

  /// Wird nach erfolgreichen Meldung aufgerufen.
  final VoidCallback onReported;

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  bool _busy = false;
  double _dragDistance = 0;

  /// Schließt den Viewer. Wird vom X-Button und der Wischgeste genutzt;
  /// der `await push`-Fortsetzungspfad der Aufrufer übernimmt dann die
  /// Rückkehr zum Dashboard bzw. den Refresh.
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

  bool _isDeletable(String storyId) => widget.deletableById[storyId] ?? false;

  bool _isReportable(String storyId) => widget.reportableById[storyId] ?? false;

  void _showViewers(String storyId) {
    showStoryViewersSheet(
      context,
      storyId: storyId,
      service: widget.service,
    );
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
    // Die Flag ist auf jeder Story sichtbar (auch eigenen); die Ownership
    // regelt das Sheet. Eigene Stories unterstützen nur `other` — ein
    // Lösch-Antrag würde die API mit `deletion_not_supported` ablehnen,
    // eigene Stories löscht der Ersteller direkt über den Löschen-Button.
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

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onVerticalDragCancel: () => _dragDistance = 0,
      child: Stack(
        fit: StackFit.expand,
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
                if (storyId == null) return const SizedBox.shrink();
                return Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, right: 16),
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
                );
              },
            ),
          ),
          SafeArea(
            child: ValueListenableBuilder<String?>(
              valueListenable: widget.currentStoryId,
              builder: (context, storyId, _) {
                if (storyId == null || !_isDeletable(storyId)) {
                  return const SizedBox.shrink();
                }
                return Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24, right: 16),
                    child: _DeleteButton(
                      onTap: _busy ? null : () => _confirmDelete(storyId),
                      busy: _busy,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
          child: const Icon(Icons.people_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
