import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart' as app_date;
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vorschlag löschen'),
        content: Text('Möchtest du „${s.title}" wirklich löschen?'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kommentar löschen'),
        content: const Text('Kommentar wirklich löschen?'),
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
      await feedback.deleteComment(widget.id, commentId);
      if (!mounted) return;
      _loadComments();
    } catch (e) {
      developer.log('Failed to delete comment', error: e);
    }
  }

  void _showEditCommentDialog(String commentId, String currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kommentar bearbeiten'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          maxLines: null,
          decoration: const InputDecoration(hintText: 'Kommentar'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                _editComment(commentId, text);
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  String _resolveUserName(String userId) {
    final auth = AppScope.of(context).auth;
    return auth.userId == userId ? 'Du' : 'Benutzer';
  }

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final isAdmin = auth.isAdmin;
    final currentUserId = auth.userId ?? '';

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_suggestion != null)
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                if (_suggestion!.userId == currentUserId || isAdmin)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Löschen',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'delete') _delete();
              },
            ),
        ],
      ),
      body: _buildBody(context, isAdmin),
    );
  }

  Widget _buildBody(BuildContext context, bool isAdmin) {
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

    final s = _suggestion!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(status: s.status),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              _VoteButtonLarge(
                count: s.upvoteCount,
                hasVoted: s.hasVoted,
                onTap: _toggleVote,
              ),
              const SizedBox(width: 20),
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Erstellt ${app_date.formatRelativeDate(s.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (s.description != null && s.description!.isNotEmpty) ...[
            Text(
              'Beschreibung',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.description!,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (isAdmin) ...[
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Admin-Aktionen',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _StatusChangeSection(
              currentStatus: s.status,
              onStatusChanged: _updateStatus,
            ),
            const SizedBox(height: 24),
          ],

          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Kommentare',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${s.commentCount}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_replyToId == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CommentInput(
                hintText: 'Kommentar hinzufügen...',
                onSubmit: (text) => _addComment(text),
              ),
            ),

          if (_replyToId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CommentInput(
                hintText: 'Antworten...',
                autofocus: true,
                onSubmit: (text) => _addComment(text, parentId: _replyToId),
                onCancel: () => setState(() => _replyToId = null),
              ),
            ),

          if (_commentsLoading)
            const Center(child: CircularProgressIndicator())
          else if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Noch keine Kommentare.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ..._comments.map(
              (comment) => CommentTile(
                comment: comment,
                currentUserId: AppScope.of(context).auth.userId ?? '',
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

class _StatusBadge extends StatelessWidget {
  final FeedbackStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status, Theme.of(context));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(FeedbackStatus status, ThemeData theme) {
    switch (status) {
      case FeedbackStatus.submitted:
        return theme.colorScheme.onSurfaceVariant;
      case FeedbackStatus.planned:
        return Colors.blue;
      case FeedbackStatus.next:
        return Colors.orange;
      case FeedbackStatus.inProgress:
        return Colors.amber.shade700;
      case FeedbackStatus.done:
        return Colors.green;
      case FeedbackStatus.cancelled:
        return theme.colorScheme.error;
      case FeedbackStatus.rejected:
        return theme.colorScheme.error;
      case FeedbackStatus.later:
        return Colors.purple;
    }
  }
}

class _VoteButtonLarge extends StatelessWidget {
  final int count;
  final bool hasVoted;
  final VoidCallback onTap;

  const _VoteButtonLarge({
    required this.count,
    required this.hasVoted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hasVoted
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasVoted
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasVoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChangeSection extends StatelessWidget {
  final FeedbackStatus currentStatus;
  final ValueChanged<FeedbackStatus> onStatusChanged;

  const _StatusChangeSection({
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FeedbackStatus.values.map((status) {
        final isActive = status == currentStatus;
        return ChoiceChip(
          label: Text(status.label),
          selected: isActive,
          onSelected: isActive
              ? null
              : (_) => onStatusChanged(status),
        );
      }).toList(),
    );
  }
}
