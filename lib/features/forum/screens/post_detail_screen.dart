import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../moderation/models/moderation_models.dart';
import '../../moderation/widgets/moderation_request_sheet.dart';
import '../models/forum_models.dart';
import '../widgets/post_detail_widgets.dart';

class PostDetailScreen extends StatefulWidget {
  final String forumId;
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.forumId,
    required this.postId,
  });

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
      _markPostRead();
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

  Future<void> _markPostRead() async {
    try {
      final scope = AppScope.of(context);
      final ids = scope.notification.unreadIdsForPost(widget.postId);
      if (ids.isEmpty) return;
      final token = await scope.auth.getAccessToken();
      await scope.notification.markRead(ids, token: token);
    } catch (e) {
      developer.log('markPostRead failed', error: e);
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
          userName: list[i].userName,
          userImage: list[i].userImage,
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
          userName: list[i].userName,
          userImage: list[i].userImage,
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
    try {
      final forumService = AppScope.of(context).forum;
      await forumService.deleteComment(
        widget.forumId,
        widget.postId,
        commentId,
      );
      if (!mounted) return;
      _loadComments();
    } on ApiException catch (e) {
      developer.log('Failed to delete comment', error: e);
      if (!mounted) return;
      if (e.errorCode == 'edit_window_expired') {
        await showModerationRequestSheet(
          context,
          objectType: ModerationObjectType.forumPost,
          objectId: widget.postId,
          objectName: _post?.title ?? _post?.text ?? 'Beitrag',
          isOwn: true,
        );
      }
    } catch (e) {
      developer.log('Failed to delete comment', error: e);
    }
  }

  Future<void> _report() async {
    final post = _post;
    if (post == null) return;
    await showModerationRequestSheet(
      context,
      objectType: ModerationObjectType.forumPost,
      objectId: post.id,
      objectName: post.title ?? post.text ?? 'Beitrag',
      isOwn: false,
    );
  }

  Future<void> _reportComment(String commentId) async {
    await showModerationRequestSheet(
      context,
      objectType: ModerationObjectType.forumComment,
      objectId: commentId,
      objectName: 'Kommentar',
      isOwn: false,
    );
  }

  Future<void> _handleVote(FeedPost post) async {
    try {
      final forumService = AppScope.of(context).forum;
      if (post.hasVoted) {
        await forumService.removeVotePost(widget.forumId, post.id);
      } else {
        await forumService.votePost(widget.forumId, post.id);
      }
      if (!mounted) return;
      setState(() {
        _post = FeedPost(
          id: post.id,
          forumId: post.forumId,
          userId: post.userId,
          userName: post.userName,
          userImage: post.userImage,
          type: post.type,
          content: post.content,
          upvoteCount: post.hasVoted
              ? post.upvoteCount - 1
              : post.upvoteCount + 1,
          commentCount: post.commentCount,
          hasVoted: !post.hasVoted,
          isDraft: post.isDraft,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
        );
      });
    } catch (e) {
      developer.log('Vote failed', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final auth = AppScope.of(context).auth;
    final isAdmin = auth.isAdmin;
    final currentUserId = auth.userId ?? '';

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            title: _post?.title ?? 'Beitrag',
            actions: [
              if (_post != null)
                DesignIconButton(icon: Icons.flag_rounded, onPressed: _report),
            ],
          ),
          Expanded(child: _buildBody(context, tokens, currentUserId, isAdmin)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DesignTokens tokens,
    String currentUserId,
    bool isAdmin,
  ) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: tokens.danger),
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
          ),
        ),
      );
    }

    final post = _post!;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceLg),
        child: Column(
          children: [
            PostDetailCard(
              post: post,
              hasVoted: post.hasVoted,
              upvoteCount: post.upvoteCount,
              onVote: () => _handleVote(post),
            ),
            SizedBox(height: tokens.spaceMd),
            PostCommentsCard(
              commentTotal: _commentTotal,
              replyToId: _replyToId,
              commentsLoading: _commentsLoading,
              comments: _comments,
              currentUserId: currentUserId,
              isAdmin: isAdmin,
              onReply: (id) => setState(() {
                _replyToId = id.isEmpty ? null : id;
              }),
              onAddComment: (text, {parentId}) =>
                  _addComment(text, parentId: parentId ?? _replyToId),
              onDeleteComment: _deleteComment,
              onReportComment: _reportComment,
            ),
            SizedBox(height: tokens.spaceLg),
          ],
        ),
      ),
    );
  }
}
