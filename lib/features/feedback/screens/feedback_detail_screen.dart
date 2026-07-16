import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/feedback_models.dart';
import '../widgets/comment_input.dart';
import '../widgets/comment_tile.dart';

class FeedbackDetailScreen extends StatefulWidget {
  final String id;

  const FeedbackDetailScreen({super.key, required this.id});

  @override
  State<FeedbackDetailScreen> createState() => _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends State<FeedbackDetailScreen> {
  FeedbackSuggestion? _suggestion;
  bool _loading = true;
  String? _error;

  List<FeedbackComment> _comments = [];
  bool _commentsLoading = false;
  String? _replyToId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_suggestion == null && _loading) {
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
      final match = response.data.where((s) => s.id == widget.id);
      if (!mounted) return;
      if (match.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Vorschlag nicht gefunden.';
        });
        return;
      }
      setState(() {
        _suggestion = match.first;
        _loading = false;
      });
      _loadComments();
    } catch (e, st) {
      developer.log('Failed to load suggestion', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Vorschlag konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _toggleVote() async {
    final s = _suggestion;
    if (s == null) return;
    try {
      final feedback = AppScope.of(context).feedback;
      if (s.hasVoted) {
        await feedback.removeVote(s.id);
      } else {
        await feedback.vote(s.id);
      }
      if (!mounted) return;
      setState(() {
        _suggestion = FeedbackSuggestion(
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
      });
    } catch (e) {
      developer.log('Vote failed', error: e);
    }
  }

  Future<void> _updateStatus(FeedbackStatus newStatus) async {
    final s = _suggestion;
    if (s == null) return;
    try {
      final feedback = AppScope.of(context).feedback;
      await feedback.updateStatus(s.id, newStatus);
      if (!mounted) return;
      setState(() {
        _suggestion = FeedbackSuggestion(
          id: s.id,
          userId: s.userId,
          title: s.title,
          description: s.description,
          status: newStatus,
          upvoteCount: s.upvoteCount,
          hasVoted: s.hasVoted,
          createdAt: s.createdAt,
          updatedAt: s.updatedAt,
        );
      });
    } catch (e) {
      developer.log('Status update failed', error: e);
    }
  }

  Future<void> _delete() async {
    final s = _suggestion;
    if (s == null) return;
    final tokens = DesignTheme.of(context);
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesignText(
            'Vorschlag löschen',
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          DesignText(
            'Möchtest du „${s.title}" wirklich löschen?',
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
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignButton(
                  label: 'Löschen',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final feedback = AppScope.of(context).feedback;
      await feedback.delete(s.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      developer.log('Delete failed', error: e);
    }
  }

  Future<void> _loadComments() async {
    setState(() => _commentsLoading = true);
    try {
      final feedback = AppScope.of(context).feedback;
      final response = await feedback.listComments(widget.id);
      if (!mounted) return;
      setState(() {
        _comments = response.data;
        _commentsLoading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load comments', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _commentsLoading = false);
    }
  }

  Future<void> _addComment(String text, {String? parentId}) async {
    try {
      final feedback = AppScope.of(context).feedback;
      final comment = await feedback.createComment(
        widget.id,
        text: text,
        parentId: parentId,
      );
      if (!mounted) return;
      setState(() {
        _replyToId = null;
        _insertComment(_comments, comment, parentId);
      });
    } catch (e) {
      developer.log('Failed to create comment', error: e);
    }
  }

  void _insertComment(
    List<FeedbackComment> list,
    FeedbackComment comment,
    String? parentId,
  ) {
    if (parentId == null) {
      list.add(comment);
      return;
    }
    for (var i = 0; i < list.length; i++) {
      if (list[i].id == parentId) {
        list[i] = FeedbackComment(
          id: list[i].id,
          suggestionId: list[i].suggestionId,
          userId: list[i].userId,
          parentId: list[i].parentId,
          text: list[i].text,
          createdAt: list[i].createdAt,
          updatedAt: list[i].updatedAt,
          children: [...list[i].children, comment],
        );
        return;
      }
      if (list[i].children.isNotEmpty) {
        final updated = List<FeedbackComment>.from(list[i].children);
        _insertComment(updated, comment, parentId);
        list[i] = FeedbackComment(
          id: list[i].id,
          suggestionId: list[i].suggestionId,
          userId: list[i].userId,
          parentId: list[i].parentId,
          text: list[i].text,
          createdAt: list[i].createdAt,
          updatedAt: list[i].updatedAt,
          children: updated,
        );
        return;
      }
    }
  }

  Future<void> _editComment(String commentId, String newText) async {
    try {
      final feedback = AppScope.of(context).feedback;
      final updated = await feedback.updateComment(
        widget.id,
        commentId,
        text: newText,
      );
      if (!mounted) return;
      setState(() => _replaceComment(_comments, updated));
    } catch (e) {
      developer.log('Failed to edit comment', error: e);
    }
  }

  void _replaceComment(List<FeedbackComment> list, FeedbackComment updated) {
    for (var i = 0; i < list.length; i++) {
      if (list[i].id == updated.id) {
        list[i] = FeedbackComment(
          id: updated.id,
          suggestionId: updated.suggestionId,
          userId: updated.userId,
          parentId: updated.parentId,
          text: updated.text,
          createdAt: updated.createdAt,
          updatedAt: updated.updatedAt,
          children: updated.children,
        );
        return;
      }
      if (list[i].children.isNotEmpty) {
        final updatedChildren = List<FeedbackComment>.from(list[i].children);
        _replaceComment(updatedChildren, updated);
        list[i] = FeedbackComment(
          id: list[i].id,
          suggestionId: list[i].suggestionId,
          userId: list[i].userId,
          parentId: list[i].parentId,
          text: list[i].text,
          createdAt: list[i].createdAt,
          updatedAt: list[i].updatedAt,
          children: updatedChildren,
        );
        return;
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final tokens = DesignTheme.of(context);
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesignText(
            'Kommentar löschen',
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          DesignText(
            'Kommentar wirklich löschen?',
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
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignButton(
                  label: 'Löschen',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final feedback = AppScope.of(context).feedback;
      await feedback.deleteComment(widget.id, commentId);
      if (!mounted) return;
      _loadComments();
    } catch (e) {
      developer.log('Failed to delete comment', error: e);
    }
  }

  void _showEditCommentDialog(String commentId, String currentText) {
    final controller = TextEditingController(text: currentText);
    final tokens = DesignTheme.of(context);
    showDesignSheet(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesignText(
            'Kommentar bearbeiten',
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          _styledField(controller: controller, hint: 'Kommentar'),
          SizedBox(height: tokens.spaceLg),
          Row(
            children: [
              Expanded(
                child: DesignButton(
                  variant: DesignButtonVariant.outlined,
                  label: 'Abbrechen',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignButton(
                  label: 'Speichern',
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      Navigator.pop(context);
                      _editComment(commentId, text);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _resolveUserName(String userId) {
    final auth = AppScope.of(context).auth;
    return auth.userId == userId ? 'Du' : 'Benutzer';
  }

  Color _statusColor(FeedbackStatus status, DesignTokens tokens) {
    switch (status) {
      case FeedbackStatus.submitted:
        return tokens.textLow;
      case FeedbackStatus.planned:
        return Colors.blue;
      case FeedbackStatus.next:
        return Colors.orange;
      case FeedbackStatus.inProgress:
        return Colors.amber.shade700;
      case FeedbackStatus.done:
        return tokens.success;
      case FeedbackStatus.cancelled:
      case FeedbackStatus.rejected:
        return tokens.danger;
      case FeedbackStatus.later:
        return Colors.purple;
    }
  }

  Widget _styledField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    final tokens = DesignTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd,
        vertical: tokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(
          color: tokens.border.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: tokens.bodyStyle(tokens.textHigh),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: tokens.bodyStyle(tokens.textLow),
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final isAdmin = auth.isAdmin;
    final currentUserId = auth.userId ?? '';

    final appBar = DesignAppBar(
      leading: DesignIconButton(
        icon: Icons.arrow_back_rounded,
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_suggestion != null &&
            (_suggestion!.userId == currentUserId || isAdmin))
          DesignIconButton(
            icon: Icons.more_vert_rounded,
            onPressed: _delete,
          ),
      ],
    );

    return DesignSurface(
      child: Column(
        children: [
          appBar,
          Expanded(child: _buildBody(context, isAdmin)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isAdmin) {
    final tokens = DesignTheme.of(context);

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
              color: tokens.danger,
            ),
            SizedBox(height: tokens.spaceSm),
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
      );
    }

    final s = _suggestion!;

    return SingleChildScrollView(
      child: Column(
        children: [
          DesignCard(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DesignText(
                        s.title,
                        style: DesignTextStyle.title,
                        color: tokens.textHigh,
                      ),
                    ),
                    SizedBox(width: tokens.spaceMd),
                    DesignBadge(
                      label: s.status.label,
                      color: _statusColor(s.status, tokens),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceLg),
                Row(
                  children: [
                    DesignButton(
                      variant: s.hasVoted
                          ? DesignButtonVariant.filled
                          : DesignButtonVariant.outlined,
                      icon: s.hasVoted
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      label: '${s.upvoteCount}',
                      onPressed: _toggleVote,
                    ),
                    SizedBox(width: tokens.spaceLg),
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: tokens.textLow.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: tokens.spaceXs),
                    DesignText(
                      'Erstellt ${app_date.formatRelativeDate(s.createdAt)}',
                      style: DesignTextStyle.label,
                      color: tokens.textLow.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                if (s.description != null &&
                    s.description!.isNotEmpty) ...[
                  SizedBox(height: tokens.spaceLg),
                  DesignText(
                    'Beschreibung',
                    style: DesignTextStyle.subtitle,
                    color: tokens.primary,
                  ),
                  SizedBox(height: tokens.spaceSm),
                  DesignText(
                    s.description!,
                    style: DesignTextStyle.body,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: tokens.spaceMd),

          if (isAdmin)
            DesignCard(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignText(
                    'Admin-Aktionen',
                    style: DesignTextStyle.subtitle,
                    color: tokens.primary,
                  ),
                  SizedBox(height: tokens.spaceMd),
                  Wrap(
                    spacing: tokens.spaceSm,
                    runSpacing: tokens.spaceSm,
                    children: FeedbackStatus.values.map((status) {
                      final isActive = status == s.status;
                      return DesignChip(
                        label: status.label,
                        selected: isActive,
                        onTap: isActive ? null : () => _updateStatus(status),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          if (isAdmin) SizedBox(height: tokens.spaceMd),

          DesignCard(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DesignText(
                      'Kommentare',
                      style: DesignTextStyle.subtitle,
                      color: tokens.primary,
                    ),
                    SizedBox(width: tokens.spaceSm),
                    DesignText(
                      '${s.commentCount}',
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceMd),
                if (_replyToId == null)
                  CommentInput(
                    hintText: 'Kommentar hinzufügen...',
                    onSubmit: (text) => _addComment(text),
                  )
                else
                  CommentInput(
                    hintText: 'Antworten...',
                    autofocus: true,
                    onSubmit: (text) => _addComment(text, parentId: _replyToId),
                    onCancel: () => setState(() => _replyToId = null),
                  ),
                SizedBox(height: tokens.spaceMd),
                if (_commentsLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_comments.isEmpty)
                  Center(
                    child: DesignText(
                      'Noch keine Kommentare.',
                      style: DesignTextStyle.body,
                      color: tokens.textLow,
                    ),
                  )
                else
                  ..._comments.map(
                    (comment) => Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceSm),
                      child: CommentTile(
                        comment: comment,
                        currentUserId:
                            AppScope.of(context).auth.userId ?? '',
                        isAdmin: isAdmin,
                        resolveUserName: _resolveUserName,
                        onReply: (id) => setState(() => _replyToId = id),
                        onEdit: (id) {
                          final c = _findComment(_comments, id);
                          if (c != null && c.text != null) {
                            _showEditCommentDialog(id, c.text!);
                          }
                        },
                        onDelete: _deleteComment,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: tokens.spaceLg),
        ],
      ),
    );
  }

  FeedbackComment? _findComment(List<FeedbackComment> list, String id) {
    for (final c in list) {
      if (c.id == id) return c;
      if (c.children.isNotEmpty) {
        final found = _findComment(c.children, id);
        if (found != null) return found;
      }
    }
    return null;
  }
}
