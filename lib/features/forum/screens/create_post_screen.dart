import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';

class CreatePostScreen extends StatefulWidget {
  final String forumId;

  const CreatePostScreen({super.key, required this.forumId});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String _selectedType = 'text';
  final _textController = TextEditingController();
  final List<_UrlEntry> _urls = [];
  bool _submitting = false;

  @override
  void dispose() {
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuer Beitrag'),
        actions: [
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Senden'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beitragstyp',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'text',
                  label: Text('Text'),
                  icon: Icon(Icons.text_fields_rounded, size: 18),
                ),
                ButtonSegment(
                  value: 'music',
                  label: Text('Musik'),
                  icon: Icon(Icons.music_note_rounded, size: 18),
                ),
                ButtonSegment(
                  value: 'video',
                  label: Text('Video'),
                  icon: Icon(Icons.videocam_rounded, size: 18),
                ),
                ButtonSegment(
                  value: 'web',
                  label: Text('Web'),
                  icon: Icon(Icons.language_rounded, size: 18),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedType = selection.first;
                  _urls.clear();
                });
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _textController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'Was möchtest du teilen?',
                border: OutlineInputBorder(),
              ),
            ),
            if (_selectedType != 'text') ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    _selectedType == 'music'
                        ? 'Streaming-Links'
                        : _selectedType == 'video'
                            ? 'Video-Links'
                            : 'Links',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _addUrl,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    tooltip: 'Link hinzufügen',
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (widget.type == 'music')
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<String>(
                initialValue: widget.entry.selectedPlatform,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(),
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
            )
          else if (widget.type == 'video')
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<String>(
                initialValue: widget.entry.selectedPlatform,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(),
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
          if (widget.type != 'text')
            SizedBox(
              width: widget.type == 'text' ? double.infinity : null,
            ),
          if (widget.type != 'text') const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.entry.urlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
