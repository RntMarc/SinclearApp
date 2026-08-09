import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';

class CreatePostScreen extends StatefulWidget {
  final String forumId;

  const CreatePostScreen({super.key, required this.forumId});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String _selectedType = 'text';
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  final List<_UrlEntry> _urls = [];
  bool _submitting = false;

  static const _types = [
    ('text', 'Text', Icons.text_fields_rounded),
    ('music', 'Musik', Icons.music_note_rounded),
    ('video', 'Video', Icons.videocam_rounded),
    ('web', 'Web', Icons.language_rounded),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    for (final entry in _urls) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addUrl() {
    setState(() {
      _urls.add(_UrlEntry());
    });
  }

  void _removeUrl(int index) {
    setState(() {
      _urls[index].dispose();
      _urls.removeAt(index);
    });
  }

  Map<String, dynamic> _buildContent() {
    final content = <String, dynamic>{};
    final text = _textController.text.trim();
    if (text.isNotEmpty) content['text'] = text;

    final title = _titleController.text.trim();
    if (title.isNotEmpty) content['title'] = title;

    if (_selectedType != 'text' && _urls.isNotEmpty) {
      final urlList = _urls
          .where((e) => e.urlController.text.trim().isNotEmpty)
          .map((e) {
        final platform = _selectedType == 'music'
            ? e.selectedPlatform ?? 'other'
            : _selectedType == 'video'
                ? e.selectedPlatform ?? 'other'
                : 'other';
        return {
          'platform': platform,
          'url': e.urlController.text.trim(),
        };
      }).toList();
      if (urlList.isNotEmpty) content['urls'] = urlList;
    }

    if (_selectedType == 'web') {
      final urlList = _urls
          .where((e) => e.urlController.text.trim().isNotEmpty)
          .map((e) => e.urlController.text.trim())
          .toList();
      if (urlList.isNotEmpty) {
        content.remove('urls');
        content['urls'] = urlList;
      }
    }

    return content;
  }

  Future<void> _submit() async {
    final content = _buildContent();
    if (content.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final forumService = AppScope.of(context).forum;
      await forumService.createPost(
        widget.forumId,
        type: _selectedType,
        content: content,
      );
      if (!mounted) return;
      context.go('/forum/${widget.forumId}');
    } catch (e) {
      developer.log('Failed to create post', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post konnte nicht erstellt werden.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            title: 'Neuer Beitrag',
            actions: [
              Padding(
                padding: EdgeInsets.only(right: tokens.spaceSm),
                child: DesignButton(
                  variant: DesignButtonVariant.filled,
                  label: 'Senden',
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignText(
                    'Beitragstyp',
                    style: DesignTextStyle.subtitle,
                    color: tokens.textHigh,
                  ),
                  SizedBox(height: tokens.spaceMd),
                  Row(
                    children: _types.map((t) {
                      final isSelected = _selectedType == t.$1;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: tokens.spaceSm),
                          child: DesignButton(
                            variant: isSelected
                                ? DesignButtonVariant.filled
                                : DesignButtonVariant.outlined,
                            icon: t.$3,
                            label: t.$2,
                            onPressed: () {
                              setState(() {
                                _selectedType = t.$1;
                                _urls.clear();
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: tokens.spaceXl),
                  Material(
                    type: MaterialType.transparency,
                    child: TextField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.words,
                      maxLines: 1,
                      style: TextStyle(
                        color: tokens.textHigh,
                        fontSize: 15,
                        fontFamily: tokens.fontFamily,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Titel (optional)',
                        hintStyle: TextStyle(
                          color: tokens.textLow,
                          fontSize: 15,
                          fontFamily: tokens.fontFamily,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                          borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                          borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                          borderSide: BorderSide(color: tokens.primary, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.all(tokens.spaceMd),
                        filled: true,
                        fillColor: tokens.surface,
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spaceMd),
                  Material(
                    type: MaterialType.transparency,
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      minLines: 3,
                      style: TextStyle(
                        color: tokens.textHigh,
                        fontSize: 15,
                        fontFamily: tokens.fontFamily,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Was möchtest du teilen?',
                        hintStyle: TextStyle(
                          color: tokens.textLow,
                          fontSize: 15,
                          fontFamily: tokens.fontFamily,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                          borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                          borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                          borderSide: BorderSide(color: tokens.primary, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.all(tokens.spaceMd),
                        filled: true,
                        fillColor: tokens.surface,
                      ),
                    ),
                  ),
                  if (_selectedType != 'text') ...[
                    SizedBox(height: tokens.spaceXl),
                    Row(
                      children: [
                        DesignText(
                          _selectedType == 'music'
                              ? 'Streaming-Links'
                              : _selectedType == 'video'
                                  ? 'Video-Links'
                                  : 'Links',
                          style: DesignTextStyle.subtitle,
                          color: tokens.textHigh,
                        ),
                        const Spacer(),
                        DesignIconButton(
                          icon: Icons.add_circle_outline_rounded,
                          onPressed: _addUrl,
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.spaceSm),
                    ..._urls.asMap().entries.map(
                      (entry) => _UrlField(
                        key: ValueKey(entry.key),
                        entry: entry.value,
                        type: _selectedType,
                        onRemove: () => _removeUrl(entry.key),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrlEntry {
  final TextEditingController urlController = TextEditingController();
  String? selectedPlatform;

  void dispose() => urlController.dispose();
}

class _UrlField extends StatefulWidget {
  final _UrlEntry entry;
  final String type;
  final VoidCallback onRemove;

  const _UrlField({
    super.key,
    required this.entry,
    required this.type,
    required this.onRemove,
  });

  @override
  State<_UrlField> createState() => _UrlFieldState();
}

class _UrlFieldState extends State<_UrlField> {
  @override
  void initState() {
    super.initState();
    if (widget.type == 'music' && widget.entry.selectedPlatform == null) {
      widget.entry.selectedPlatform = 'spotify';
    }
    if (widget.type == 'video' && widget.entry.selectedPlatform == null) {
      widget.entry.selectedPlatform = 'youtube';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceMd),
      child: Row(
        children: [
          if (widget.type == 'music')
            SizedBox(
              width: 140,
              child: Material(
                type: MaterialType.transparency,
                child: DropdownButtonFormField<String>(
                  initialValue: widget.entry.selectedPlatform,
                  isExpanded: true,
                  style: TextStyle(
                    color: tokens.textHigh,
                    fontSize: 15,
                    fontFamily: tokens.fontFamily,
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceMd,
                      vertical: tokens.spaceMd,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide(color: tokens.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: tokens.surface,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'spotify', child: Text('Spotify')),
                    DropdownMenuItem(
                      value: 'apple_music',
                      child: Text('Apple Music'),
                    ),
                    DropdownMenuItem(
                      value: 'youtube_music',
                      child: Text('YouTube Music'),
                    ),
                    DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                    DropdownMenuItem(value: 'other', child: Text('Sonstige')),
                  ],
                  onChanged: (v) => setState(
                    () => widget.entry.selectedPlatform = v,
                  ),
                ),
              ),
            )
          else if (widget.type == 'video')
            SizedBox(
              width: 140,
              child: Material(
                type: MaterialType.transparency,
                child: DropdownButtonFormField<String>(
                  initialValue: widget.entry.selectedPlatform,
                  isExpanded: true,
                  style: TextStyle(
                    color: tokens.textHigh,
                    fontSize: 15,
                    fontFamily: tokens.fontFamily,
                  ),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceMd,
                      vertical: tokens.spaceMd,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide(color: tokens.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: tokens.surface,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                    DropdownMenuItem(value: 'peertube', child: Text('PeerTube')),
                    DropdownMenuItem(value: 'odysee', child: Text('Odysee')),
                    DropdownMenuItem(
                      value: 'tv_mediathek',
                      child: Text('TV Mediathek'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Sonstige')),
                  ],
                  onChanged: (v) => setState(
                    () => widget.entry.selectedPlatform = v,
                  ),
                ),
              ),
            ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: widget.entry.urlController,
                keyboardType: TextInputType.url,
                style: TextStyle(
                  color: tokens.textHigh,
                  fontSize: 15,
                  fontFamily: tokens.fontFamily,
                ),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: TextStyle(
                    color: tokens.textLow,
                    fontSize: 15,
                    fontFamily: tokens.fontFamily,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                    borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                    borderSide: BorderSide(color: tokens.border.withValues(alpha: 0.8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                    borderSide: BorderSide(color: tokens.primary, width: 1.5),
                  ),
                  suffixIcon: DesignIconButton(
                    icon: Icons.remove_circle_outline_rounded,
                    onPressed: widget.onRemove,
                  ),
                  filled: true,
                  fillColor: tokens.surface,
                  contentPadding: EdgeInsets.all(tokens.spaceMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
