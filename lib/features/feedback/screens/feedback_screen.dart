import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
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

    return SuggestionList(
      suggestions: _suggestions,
      currentUserId: currentUserId,
      isAdmin: isAdmin,
      onVote: _toggleVote,
      onDelete: _deleteSuggestion,
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
