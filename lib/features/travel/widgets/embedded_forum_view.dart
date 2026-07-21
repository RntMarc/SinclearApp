import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../forum/models/forum_models.dart';
import '../../forum/screens/post_detail_screen.dart';
import '../../forum/screens/create_post_screen.dart';
import '../../forum/widgets/forum_detail_widgets.dart';

class EmbeddedForumView extends StatefulWidget {
  final String forumId;

  const EmbeddedForumView({super.key, required this.forumId});

  @override
  State<EmbeddedForumView> createState() => _EmbeddedForumViewState();
}

class _EmbeddedForumViewState extends State<EmbeddedForumView> {
  ForumDetail? _forum;
  List<FeedPost> _posts = [];
  bool _loading = true;
  bool _postsLoading = false;
  String? _error;
  int _postPage = 1;
  bool _hasMorePosts = true;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_forum == null && _loading) _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_postsLoading &&
        _hasMorePosts) {
      _loadMorePosts();
    }
  }

  Future<void> _refresh() async {
    _postPage = 1;
    _hasMorePosts = true;
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final forumService = AppScope.of(context).forum;
      final forum = await forumService.get(widget.forumId);
      if (!mounted) return;
      setState(() {
        _forum = forum;
        _loading = false;
      });
      _loadPosts();
    } catch (e, st) {
      developer.log('Failed to load forum', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Forum konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _postsLoading = true);
    try {
      final forumService = AppScope.of(context).forum;
      final response = await forumService.listPosts(
        widget.forumId,
        page: _postPage,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _posts = response.data;
        _hasMorePosts = response.meta.hasMore;
        _postsLoading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load posts', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _postsLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_postsLoading || !_hasMorePosts) return;
    setState(() {
      _postPage++;
      _postsLoading = true;
    });
    try {
      final forumService = AppScope.of(context).forum;
      final response = await forumService.listPosts(
        widget.forumId,
        page: _postPage,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _posts = [..._posts, ...response.data];
        _hasMorePosts = response.meta.hasMore;
        _postsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _postsLoading = false);
    }
  }

  Future<void> _votePost(FeedPost post) async {
    try {
      final forumService = AppScope.of(context).forum;
      if (post.hasVoted) {
        await forumService.removeVotePost(widget.forumId, post.id);
      } else {
        await forumService.votePost(widget.forumId, post.id);
      }
      setState(() {
        _posts = _posts.map((p) {
          if (p.id != post.id) return p;
          return FeedPost(
            id: p.id,
            forumId: p.forumId,
            userId: p.userId,
            userName: p.userName,
            userImage: p.userImage,
            type: p.type,
            content: p.content,
            upvoteCount: p.hasVoted ? p.upvoteCount - 1 : p.upvoteCount + 1,
            commentCount: p.commentCount,
            hasVoted: !p.hasVoted,
            createdAt: p.createdAt,
            updatedAt: p.updatedAt,
          );
        }).toList();
      });
    } catch (e) {
      developer.log('Vote failed', error: e);
    }
  }

  Future<void> _deletePost(FeedPost post) async {
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'Post löschen',
            style: DesignTextStyle.subtitle,
            color: DesignTheme.of(context).textHigh,
          ),
          SizedBox(height: DesignTheme.of(context).spaceMd),
          DesignText(
            'Möchtest du diesen Post wirklich löschen?',
            style: DesignTextStyle.body,
            color: DesignTheme.of(context).textHigh,
          ),
          SizedBox(height: DesignTheme.of(context).spaceXl),
          DesignButton(
            variant: DesignButtonVariant.filled,
            label: 'Löschen',
            fullWidth: true,
            onPressed: () => Navigator.pop(context, true),
          ),
          SizedBox(height: DesignTheme.of(context).spaceSm),
          DesignButton(
            variant: DesignButtonVariant.outlined,
            label: 'Abbrechen',
            fullWidth: true,
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final forumService = AppScope.of(context).forum;
      await forumService.deletePost(widget.forumId, post.id);
      if (!mounted) return;
      setState(() {
        _posts = _posts.where((p) => p.id != post.id).toList();
      });
    } catch (e) {
      developer.log('Delete post failed', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final auth = AppScope.of(context).auth;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }

    if (_error != null) {
      return Center(
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
              variant: DesignButtonVariant.filled,
              label: 'Erneut versuchen',
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    final forum = _forum!;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.only(
                left: tokens.spaceLg,
                right: tokens.spaceLg,
                top: tokens.spaceSm,
                bottom: tokens.spaceXxl,
              ),
              child: Column(
                children: [
                  ForumHeaderCard(forum: forum),
                  SizedBox(height: tokens.spaceMd),
                  const DesignDivider(),
                  SizedBox(height: tokens.spaceMd),
                  ForumPostList(
                    postsLoading: _postsLoading,
                    posts: _posts,
                    isMember: forum.isMember,
                    hasMorePosts: _hasMorePosts,
                    currentUserId: auth.userId ?? '',
                    isAdmin: auth.isAdmin,
                    forumId: widget.forumId,
                    onVote: _votePost,
                    onDelete: _deletePost,
                    onPostTap: (fid, pid) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PostDetailScreen(forumId: fid, postId: pid),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_forum?.isMember == true)
          Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: DesignButton(
              variant: DesignButtonVariant.filled,
              icon: Icons.add_rounded,
              label: 'Neuer Beitrag',
              fullWidth: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CreatePostScreen(forumId: widget.forumId),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
