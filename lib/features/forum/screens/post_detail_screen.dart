import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../models/forum_models.dart';
import '../widgets/comment_tree.dart';

class PostDetailScreen extends StatefulWidget {
  final String forumId;
  final String postId;

  const PostDetailScreen({super.key, required this.forumId, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  FeedPost? _post;
  List<FeedPostComment> _comments = [];
  bool _loading = true;
  bool _commentsLoading = false;
  String? _error;
  String? _replyToId;
  int _commentTotal = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_post == null && _loading) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final forumService = AppScope.of(context).forum;
      final response = await forumService.listPosts(widget.forumId, limit: 100);
      final match = response.data.where((p) => p.id == widget.postId);
      if (!mounted) return;
      if (match.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Post nicht gefunden.';
        });
        return;
      }
      setState(() {
        _post = match.first;
        _loading = false;
      });
      _loadComments();
    } catch (e, st) {
      developer.log('Failed to load post', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Post konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() => _commentsLoading = true);
    try {
      final forumService = AppScope.of(context).forum;
      final response = await forumService.listComments(
        widget.forumId,
        widget.postId,
      );
      if (!mounted) return;
      setState(() {
        _comments = response.data;
        _commentTotal = response.total;
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
      final forumService = AppScope.of(context).forum;
      final comment = await forumService.createComment(
        widget.forumId,
        widget.postId,
        text: text,
        parentId: parentId,
      );
      if (!mounted) return;
      setState(() {
        _replyToId = null;
        _commentTotal++;
        _insertComment(_comments, comment, parentId);
      });
    } catch (e) {
      developer.log('Failed to create comment', error: e);
    }
  }

  void _insertComment(
    List<FeedPostComment> list,
    FeedPostComment comment,
    String? parentId,
  ) {
    if (parentId == null) {
      list.add(comment);
      return;
    }
    for (var i = 0; i < list.length; i++) {
      if (list[i].id == parentId) {
        list[i] = FeedPostComment(
          id: list[i].id,
          postId: list[i].postId,
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
        final updated = List<FeedPostComment>.from(list[i].children);
        _insertComment(updated, comment, parentId);
        list[i] = FeedPostComment(
          id: list[i].id,
          postId: list[i].postId,
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
      final forumService = AppScope.of(context).forum;
      await forumService.deleteComment(
        widget.forumId,
        widget.postId,
        commentId,
      );
      if (!mounted) return;
      _loadComments();
    } catch (e) {
      developer.log('Failed to delete comment', error: e);
    }
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
        title: const Text('Beitrag'),
      ),
      body: _buildBody(context, currentUserId, isAdmin),
    );
  }

  Widget _buildBody(BuildContext context, String currentUserId, bool isAdmin) {
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

    final post = _post!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _typeIcon(post.type),
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _typeLabel(post.type),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                app_date.formatRelativeDate(post.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ],
          ),
          if (post.text != null && post.text!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              post.text!,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ],
          if (post.type != 'text' && post.urls.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...post.urls.map(
              (url) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => launchUrl(Uri.parse(url.url)),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                url.platform.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                Uri.tryParse(url.url)?.host ?? url.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    final forumService = AppScope.of(context).forum;
                    if (post.hasVoted) {
                      await forumService.removeVotePost(
                        widget.forumId,
                        post.id,
                      );
                    } else {
                      await forumService.votePost(widget.forumId, post.id);
                    }
                    if (!mounted) return;
                    setState(() {
                      _post = FeedPost(
                        id: post.id,
                        forumId: post.forumId,
                        userId: post.userId,
                        type: post.type,
                        content: post.content,
                        upvoteCount:
                            post.hasVoted ? post.upvoteCount - 1 : post.upvoteCount + 1,
                        commentCount: post.commentCount,
                        hasVoted: !post.hasVoted,
                        createdAt: post.createdAt,
                        updatedAt: post.updatedAt,
                      );
                    });
                  } catch (e) {
                    developer.log('Vote failed', error: e);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      post.hasVoted
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      size: 20,
                      color: post.hasVoted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.upvoteCount}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: post.hasVoted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            'Kommentare ($_commentTotal)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
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
              (comment) => CommentTreeTile(
                comment: comment,
                currentUserId: currentUserId,
                isAdmin: isAdmin,
                resolveUserName: _resolveUserName,
                onReply: (id) => setState(() => _replyToId = id),
                onDelete: _deleteComment,
              ),
            ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'music':
        return Icons.music_note_rounded;
      case 'video':
        return Icons.videocam_rounded;
      case 'web':
        return Icons.language_rounded;
      default:
        return Icons.text_fields_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'music':
        return 'Musik';
      case 'video':
        return 'Video';
      case 'web':
        return 'Web';
      default:
        return 'Text';
    }
  }
}
