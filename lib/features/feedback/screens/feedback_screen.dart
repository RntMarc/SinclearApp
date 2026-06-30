import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_compressor.dart';
import '../models/feedback_models.dart';
import '../widgets/suggestion_list.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  List<FeedbackSuggestion> _suggestions = [];
  bool _loading = true;
  bool _hasLoaded = false;
  String? _error;

  bool _bugReportExpanded = false;
  final _bugTextController = TextEditingController();
  final _bugVersionController = TextEditingController();
  final _bugBuildController = TextEditingController();
  Uint8List? _bugScreenshot;
  bool _bugSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
      _loadVersionInfo();
    }
  }

  @override
  void dispose() {
    _bugTextController.dispose();
    _bugVersionController.dispose();
    _bugBuildController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feedback = AppScope.of(context).feedback;
      final response = await feedback.list(limit: 100);
      if (!mounted) return;
      setState(() {
        _suggestions = response.data;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load feedback', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Vorschläge konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadVersionInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      _bugVersionController.text = info.version;
      _bugBuildController.text = info.buildNumber;
    } catch (e) {
      developer.log('Failed to load package info', error: e);
    }
  }

  Future<void> _toggleVote(FeedbackSuggestion suggestion) async {
    try {
      final feedback = AppScope.of(context).feedback;
      if (suggestion.hasVoted) {
        await feedback.removeVote(suggestion.id);
      } else {
        await feedback.vote(suggestion.id);
      }
      if (!mounted) return;
      setState(() {
        _suggestions = _suggestions.map((s) {
          if (s.id != suggestion.id) return s;
          return FeedbackSuggestion(
            id: s.id,
            userId: s.userId,
            title: s.title,
            description: s.description,
            status: s.status,
            upvoteCount: s.hasVoted ? s.upvoteCount - 1 : s.upvoteCount + 1,
            hasVoted: !s.hasVoted,
            createdAt: s.createdAt,
            updatedAt: s.updatedAt,
          );
        }).toList();
      });
    } catch (e) {
      developer.log('Vote failed', error: e);
    }
  }

  Future<void> _deleteSuggestion(FeedbackSuggestion suggestion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vorschlag löschen'),
        content: Text(
          'Möchtest du „${suggestion.title}" wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final feedback = AppScope.of(context).feedback;
      await feedback.delete(suggestion.id);
      if (!mounted) return;
      setState(() {
        _suggestions.removeWhere((s) => s.id == suggestion.id);
      });
    } catch (e) {
      developer.log('Delete failed', error: e);
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateSuggestionSheet(
        onSubmit: (title, description) async {
          try {
            final feedback = AppScope.of(context).feedback;
            final created = await feedback.create(
              title: title,
              description: description,
            );
            if (!mounted) return;
            setState(() => _suggestions.insert(0, created));
            Navigator.pop(context);
          } catch (e) {
            developer.log('Create failed', error: e);
            rethrow;
          }
        },
      ),
    );
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 4000,
      maxHeight: 4000,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final compressed = compressImage(bytes);
    if (!mounted) return;
    setState(() => _bugScreenshot = compressed);
  }

  Future<void> _submitBugReport() async {
    final text = _bugTextController.text.trim();
    if (text.isEmpty) return;

    setState(() => _bugSubmitting = true);
    try {
      final feedback = AppScope.of(context).feedback;
      final version = _bugVersionController.text.trim();
      final buildText = _bugBuildController.text.trim();
      final buildNumber = int.tryParse(buildText);

      String? imageBase64;
      if (_bugScreenshot != null) {
        imageBase64 = base64Encode(_bugScreenshot!);
      }

      await feedback.submitBugReport(
        text: text,
        version: version.isEmpty ? null : version,
        buildNumber: buildNumber,
        image: imageBase64,
      );

      if (!mounted) return;
      setState(() {
        _bugReportExpanded = false;
        _bugTextController.clear();
        _bugScreenshot = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bug-Report erfolgreich gesendet.')),
      );
    } catch (e) {
      developer.log('Bug report failed', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bug-Report konnte nicht gesendet werden.')),
      );
    } finally {
      if (mounted) setState(() => _bugSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        tooltip: 'Neuen Vorschlag erstellen',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final currentUserId = auth.userId ?? '';
    final isAdmin = auth.isAdmin;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _load,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _BugReportSection(
          expanded: _bugReportExpanded,
          onToggle: () => setState(() => _bugReportExpanded = !_bugReportExpanded),
          textController: _bugTextController,
          versionController: _bugVersionController,
          buildController: _bugBuildController,
          screenshot: _bugScreenshot,
          submitting: _bugSubmitting,
          onPickScreenshot: _pickScreenshot,
          onRemoveScreenshot: () => setState(() => _bugScreenshot = null),
          onSubmit: _submitBugReport,
        ),
        Expanded(
          child: SuggestionList(
            suggestions: _suggestions,
            currentUserId: currentUserId,
            isAdmin: isAdmin,
            onVote: _toggleVote,
            onDelete: _deleteSuggestion,
          ),
        ),
      ],
    );
  }
}

class _CreateSuggestionSheet extends StatefulWidget {
  final Future<void> Function(String title, String? description) onSubmit;

  const _CreateSuggestionSheet({required this.onSubmit});

  @override
  State<_CreateSuggestionSheet> createState() => _CreateSuggestionSheetState();
}

class _CreateSuggestionSheetState extends State<_CreateSuggestionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final title = _titleController.text.trim();
      final desc = _descriptionController.text.trim();
      await widget.onSubmit(title, desc.isEmpty ? null : desc);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'Erstellen fehlgeschlagen.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Neuer Vorschlag',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Titel *',
                hintText: 'Kurze Überschrift für deinen Vorschlag',
              ),
              maxLength: 255,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bitte gib einen Titel ein.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'Was genau schlägst du vor?',
              ),
              maxLines: 3,
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 8),
              Text(
                _submitError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BugReportSection extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController textController;
  final TextEditingController versionController;
  final TextEditingController buildController;
  final Uint8List? screenshot;
  final bool submitting;
  final VoidCallback onPickScreenshot;
  final VoidCallback onRemoveScreenshot;
  final VoidCallback onSubmit;

  const _BugReportSection({
    required this.expanded,
    required this.onToggle,
    required this.textController,
    required this.versionController,
    required this.buildController,
    required this.screenshot,
    required this.submitting,
    required this.onPickScreenshot,
    required this.onRemoveScreenshot,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.bug_report_outlined,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bug melden',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: textController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Bug-Beschreibung *',
                      hintText: 'Was ist passiert?',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: versionController,
                          decoration: const InputDecoration(
                            labelText: 'Version',
                            hintText: 'z.B. 0.5.0',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: buildController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Build',
                            hintText: 'z.B. 5',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (screenshot != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            screenshot!,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: onRemoveScreenshot,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: onPickScreenshot,
                      icon: const Icon(Icons.screenshot_monitor_rounded, size: 18),
                      label: const Text('Screenshot hinzufügen'),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: submitting ? null : onSubmit,
                    child: submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Bug-Report senden'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
