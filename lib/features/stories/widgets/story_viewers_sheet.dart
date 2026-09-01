import 'package:flutter/material.dart';

import '../../../core/image/image_provider_helper.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../models/stories_models.dart';
import '../services/stories_service.dart';

/// Zeigt ein Bottom Sheet mit der Liste der Nutzer, die eine Story gesehen
/// haben. Nur für den Ersteller der Story oder Admins aufrufbar.
///
/// Lädt die Viewer-Liste beim Öffnen und zeigt sie mit Avatar, Name und
/// Zeitstempel an.
Future<void> showStoryViewersSheet(
  BuildContext context, {
  required String storyId,
  required StoriesService service,
}) {
  return showDesignSheet(
    context: context,
    child: _StoryViewersContent(storyId: storyId, service: service),
  );
}

class _StoryViewersContent extends StatefulWidget {
  const _StoryViewersContent({
    required this.storyId,
    required this.service,
  });

  final String storyId;
  final StoriesService service;

  @override
  State<_StoryViewersContent> createState() => _StoryViewersContentState();
}

class _StoryViewersContentState extends State<_StoryViewersContent> {
  bool _loading = true;
  String? _error;
  List<StoryViewerItem> _viewers = const [];

  @override
  void initState() {
    super.initState();
    _loadViewers();
  }

  Future<void> _loadViewers() async {
    try {
      final viewers = await widget.service.getViewers(widget.storyId);
      if (!mounted) return;
      setState(() {
        _viewers = viewers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _parseError(e);
        _loading = false;
      });
    }
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('403')) return 'Keine Berechtigung.';
    return 'Zuschauer konnten nicht geladen werden.';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(
          'Zuschauer',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceSm),
        if (_loading) ...[
          SizedBox(height: tokens.spaceLg),
          const Center(child: CircularProgressIndicator()),
          SizedBox(height: tokens.spaceLg),
        ] else if (_error != null) ...[
          SizedBox(height: tokens.spaceLg),
          Center(
            child: DesignText(
              _error!,
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          ),
          SizedBox(height: tokens.spaceLg),
        ] else if (_viewers.isEmpty) ...[
          SizedBox(height: tokens.spaceLg),
          Center(
            child: DesignText(
              'Noch niemand hat diese Story gesehen.',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          ),
          SizedBox(height: tokens.spaceLg),
        ] else ...[
          for (var i = 0; i < _viewers.length; i++) _ViewerTile(viewer: _viewers[i]),
        ],
      ],
    );
  }
}

class _ViewerTile extends StatelessWidget {
  const _ViewerTile({required this.viewer});

  final StoryViewerItem viewer;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final timeLabel = formatRelativeDayTime(viewer.viewedAt);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
      child: Row(
        children: [
          _avatar(viewer, tokens),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  viewer.displayName,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                ),
                DesignText(
                  timeLabel,
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(StoryViewerItem viewer, DesignTokens tokens) {
    final provider = resolveImageProvider(viewer.avatar);
    if (provider != null) {
      return ClipOval(
        child: Image(
          image: provider,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initials(viewer.displayName, tokens),
        ),
      );
    }
    return _initials(viewer.displayName, tokens);
  }

  Widget _initials(String name, DesignTokens tokens) {
    final initials = name.trim().isEmpty
        ? ''
        : name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.surfaceVariant,
      ),
      alignment: Alignment.center,
      child: DesignText(
        initials,
        style: DesignTextStyle.label,
        color: tokens.primary,
      ),
    );
  }
}
