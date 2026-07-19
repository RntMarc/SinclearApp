import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../models/feedback_models.dart';
import '../services/feedback_service.dart';
import '../widgets/suggestion_list.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  List<FeedbackSuggestion> _suggestions = [];
  bool _loading = true;
  String? _error;
  bool _creating = false;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _bugText = TextEditingController();
  Uint8List? _screenshotBytes;
  bool _sendingBug = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _load();
  }

  FeedbackService get _feedback => AppScope.of(context).feedback;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _feedback.list(limit: 50);
      if (!mounted) return;
      setState(() {
        _suggestions = response.data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Vorschläge konnten nicht geladen werden.';
        _loading = false;
      });
    }
  }

  Future<void> _vote(String id) async {
    final current = _suggestions.where((s) => s.id == id).firstOrNull;
    if (current == null) return;
    try {
      if (current.hasVoted) {
        await _feedback.removeVote(id);
      } else {
        await _feedback.vote(id);
      }
      if (!mounted) return;
      setState(() {
        _suggestions = _suggestions.map((s) {
          if (s.id != id) return s;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stimme konnte nicht abgegeben werden: $e')),
        );
      }
    }
  }

  Future<void> _deleteSuggestion(String id) async {
    try {
      await _feedback.delete(id);
      if (!mounted) return;
      setState(
        () => _suggestions = _suggestions.where((s) => s.id != id).toList(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: $e')));
      }
    }
  }

  Future<void> _submitSuggestion() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    if (title.isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      final created = await _feedback.create(
        title: title,
        description: description.isEmpty ? null : description,
      );
      if (!mounted) return;
      _titleController.clear();
      _descController.clear();
      Navigator.of(context).pop();
      setState(() => _suggestions = [created, ..._suggestions]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vorschlag konnte nicht erstellt werden: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _sendBugReport() async {
    final text = _bugText.text.trim();
    if (text.isEmpty || _sendingBug) return;
    setState(() => _sendingBug = true);
    try {
      String? imageBase64;
      if (_screenshotBytes != null) {
        imageBase64 = base64Encode(_screenshotBytes!);
      }
      await _feedback.submitBugReport(text: text, image: imageBase64);
      if (!mounted) return;
      _bugText.clear();
      setState(() => _screenshotBytes = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehlerbericht gesendet. Danke!')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehlerbericht fehlgeschlagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingBug = false);
    }
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _screenshotBytes = bytes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _bugText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final currentUserId = auth.userId ?? '';
    final isAdmin = auth.isAdmin;
    return DesignSurface(child: _buildBody(currentUserId, isAdmin));
  }

  Widget _buildBody(String currentUserId, bool isAdmin) {
    final tokens = DesignTheme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: tokens.danger),
                  SizedBox(height: tokens.spaceMd),
                  DesignText(
                    _error!,
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                  SizedBox(height: tokens.spaceLg),
                  DesignButton(
                    variant: DesignButtonVariant.outlined,
                    label: 'Erneut versuchen',
                    onPressed: _load,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceLg,
                    tokens.spaceLg,
                    tokens.spaceLg,
                    0,
                  ),
                  child: DesignText(
                    'Fehler melden',
                    style: DesignTextStyle.title,
                    color: tokens.textHigh,
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
                _bugReportSection(),
                SizedBox(height: tokens.spaceLg),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceLg,
                    0,
                    tokens.spaceLg,
                    0,
                  ),
                  child: DesignText(
                    'Vorschläge',
                    style: DesignTextStyle.title,
                    color: tokens.textHigh,
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
                SuggestionList(
                  suggestions: _suggestions,
                  currentUserId: currentUserId,
                  isAdmin: isAdmin,
                  onVote: (s) => _vote(s.id),
                  onDelete: (s) => _deleteSuggestion(s.id),
                ),
                SizedBox(height: tokens.spaceXl + 44),
              ],
            ),
          ),
        ),
        Positioned(
          right: tokens.spaceLg,
          bottom: tokens.spaceXl,
          child: DesignIconButton(
            icon: Icons.add_rounded,
            tinted: true,
            onPressed: _showCreateSheet,
          ),
        ),
      ],
    );
  }

  void _showCreateSheet() {
    showDesignSheet(context: context, child: _buildCreateSheet());
  }

  Widget _buildCreateSheet() {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DesignText(
                  'Neuer Vorschlag',
                  style: DesignTextStyle.title,
                  color: tokens.textHigh,
                ),
              ),
              DesignIconButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceLg),
          _styledField(controller: _titleController, hint: 'Titel'),
          SizedBox(height: tokens.spaceMd),
          _styledField(
            controller: _descController,
            hint: 'Beschreibung (optional)',
            maxLines: 3,
          ),
          SizedBox(height: tokens.spaceLg),
          DesignButton(
            label: 'Vorschlag erstellen',
            fullWidth: true,
            loading: _creating,
            onPressed: _creating ? null : _submitSuggestion,
          ),
          SizedBox(height: tokens.spaceXs),
        ],
      ),
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return DesignTextField(
      controller: controller,
      hint: hint,
      maxLines: maxLines,
    );
  }

  Widget _bugReportSection() {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            'Ein Problem gefunden? Schicke uns einen Fehlerbericht – '
            'gern mit Screenshot.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceMd),
          _styledField(
            controller: _bugText,
            hint: 'Beschreibe den Fehler...',
            maxLines: 3,
          ),
          SizedBox(height: tokens.spaceMd),
          Row(
            children: [
              DesignButton(
                icon: Icons.add_a_photo_outlined,
                label: 'Screenshot',
                variant: DesignButtonVariant.text,
                onPressed: _pickScreenshot,
              ),
              if (_screenshotBytes != null) ...[
                SizedBox(width: tokens.spaceMd),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      child: Image.memory(
                        _screenshotBytes!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _screenshotBytes = null),
                        child: Container(
                          decoration: BoxDecoration(
                            color: tokens.surface.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: tokens.textHigh,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: tokens.spaceMd),
                _sendingBug
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tokens.primary,
                        ),
                      )
                    : DesignButton(label: 'Senden', onPressed: _sendBugReport),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
