import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../moderation/models/moderation_models.dart';
import '../../moderation/widgets/moderation_request_sheet.dart';
import '../models/forum_models.dart';
import '../widgets/forum_detail_widgets.dart';
import '../widgets/member_sheet.dart';

class ForumDetailScreen extends StatefulWidget {
  final String id;

  const ForumDetailScreen({super.key, required this.id});

  @override
  State<ForumDetailScreen> createState() => _ForumDetailScreenState();
}

class _ForumDetailScreenState extends State<ForumDetailScreen> {
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
    if (_forum == null && _loading) {
      _load();
      _refreshUnread();
    }
  }

  Future<void> _refreshUnread() async {
    try {
      final scope = AppScope.of(context);
      final token = await scope.auth.getAccessToken();
      await scope.notification.refreshUnread(token: token);
    } catch (e) {
      developer.log('refreshUnread failed', error: e);
    }
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
      final forum = await forumService.get(widget.id);
      if (!mounted) return;
      setState(() {
        _forum = forum;
        _loading = false;
      });
      _loadPosts();
    } catch (e, st) {
      developer.log(
        'Forum load error',
        error: e,
        stackTrace: st,
        name: 'forum_detail',
      );
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
        widget.id,
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
        widget.id,
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

  Future<void> _toggleJoin() async {
    final forum = _forum;
    if (forum == null) return;
    try {
      final forumService = AppScope.of(context).forum;
      if (forum.isMember) {
        await forumService.leave(forum.id);
      } else {
        await forumService.join(forum.id);
      }
      if (!mounted) return;
      _load();
    } catch (e) {
      developer.log('Join/leave failed', error: e);
    }
  }

  Future<void> _showMembers() async {
    try {
      final forumService = AppScope.of(context).forum;
      final response = await forumService.listMembers(widget.id);
      if (!mounted) return;
      if (response.data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine Mitglieder vorhanden.')),
        );
        return;
      }
      MemberSheet.show(context, members: response.data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mitglieder konnten nicht geladen werden.'),
        ),
      );
    }
  }

  Future<void> _votePost(FeedPost post) async {
    try {
      final forumService = AppScope.of(context).forum;
      if (post.hasVoted) {
        await forumService.removeVotePost(widget.id, post.id);
      } else {
        await forumService.votePost(widget.id, post.id);
      }
      if (!mounted) return;
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
            isDraft: p.isDraft,
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
      await forumService.deletePost(widget.id, post.id);
      if (!mounted) return;
      setState(() {
        _posts = _posts.where((p) => p.id != post.id).toList();
      });
    } on ApiException catch (e) {
      developer.log('Delete post failed', error: e);
      if (!mounted) return;
      if (e.errorCode == 'edit_window_expired') {
        await showModerationRequestSheet(
          context,
          objectType: ModerationObjectType.forumPost,
          objectId: post.id,
          objectName: post.title ?? post.text ?? 'Beitrag',
          isOwn: true,
        );
      }
    } catch (e) {
      developer.log('Delete post failed', error: e);
    }
  }

  void _reportPost(FeedPost post) {
    showModerationRequestSheet(
      context,
      objectType: ModerationObjectType.forumPost,
      objectId: post.id,
      objectName: post.title ?? post.text ?? 'Beitrag',
      isOwn: post.userId == AppScope.of(context).auth.userId,
    );
  }

  Future<void> _showDraftsSheet() async {
    List<FeedPost>? drafts;
    String? error;
    try {
      final forumService = AppScope.of(context).forum;
      final response = await forumService.listDrafts(widget.id, limit: 50);
      drafts = response.data;
    } catch (e) {
      developer.log('Failed to load drafts', error: e);
      error = 'Entwürfe konnten nicht geladen werden.';
    }
    if (!mounted) return;
    showDesignSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DesignText('Entwürfe', style: DesignTextStyle.title),
          SizedBox(height: DesignTheme.of(context).spaceMd),
          if (error != null)
            Padding(
              padding: EdgeInsets.all(DesignTheme.of(context).spaceLg),
              child: Center(
                child: DesignText(
                  error,
                  color: DesignTheme.of(context).danger,
                ),
              ),
            )
          else if (drafts == null)
            Padding(
              padding: EdgeInsets.all(DesignTheme.of(context).spaceLg),
              child: Center(
                child: CircularProgressIndicator(
                  color: DesignTheme.of(context).primary,
                ),
              ),
            )
          else if (drafts.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: DesignTheme.of(context).spaceLg,
              ),
              child: Center(
                child: DesignText(
                  'Keine Entwürfe vorhanden.',
                  color: DesignTheme.of(context).textLow,
                ),
              ),
            )
          else
            ...drafts.map((draft) => _draftTile(draft)),
        ],
      ),
    );
  }

  Widget _draftTile(FeedPost draft) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      margin: EdgeInsets.only(bottom: tokens.spaceSm),
      useGlass: false,
      onTap: () {
        Navigator.pop(context);
        context.go('/forum/${widget.id}/bearbeiten/${draft.id}');
      },
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceSm),
        child: Row(
          children: [
            Icon(
              _typeIcon(draft.type),
              size: 24,
              color: tokens.textLow,
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignText(
                    draft.title ?? draft.text ?? 'Entwurf',
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: tokens.spaceXs),
                  DesignText(
                    draft.type[0].toUpperCase() + draft.type.substring(1),
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: tokens.textLow),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) => switch (type) {
    'music' => Icons.music_note_rounded,
    'video' => Icons.videocam_rounded,
    'web' => Icons.language_rounded,
    _ => Icons.text_fields_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final auth = AppScope.of(context).auth;

    return DesignSurface(
      child: Stack(
        children: [
          Column(
            children: [
              DesignSubpageHeader(
                leading: DesignIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
                title: _forum?.name ?? 'Forum',
                actions: [
                  DesignIconButton(
                    icon: Icons.people_rounded,
                    onPressed: _showMembers,
                  ),
                ],
              ),
              Expanded(child: _buildBody(context, tokens, auth)),
              if (_forum?.isMember == true)
                Padding(
                  padding: EdgeInsets.all(tokens.spaceLg),
                  child: DesignButton(
                    variant: DesignButtonVariant.filled,
                    icon: Icons.add_rounded,
                    label: 'Neuer Beitrag',
                    fullWidth: true,
                    onPressed: () =>
                        context.go('/forum/${widget.id}/erstellen'),
                  ),
                ),
            ],
          ),
          if (_forum?.isMember == true)
            Positioned(
              bottom: tokens.spaceLg + 56,
              right: tokens.spaceLg,
              child: DesignIconButton(
                icon: Icons.edit_note_rounded,
                onPressed: _showDraftsSheet,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DesignTokens tokens, dynamic auth) {
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

    return RefreshIndicator(
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
            ForumHeaderCard(forum: forum, onToggleJoin: _toggleJoin),
            SizedBox(height: tokens.spaceMd),
            const DesignDivider(),
            SizedBox(height: tokens.spaceMd),
            ListenableBuilder(
              listenable: AppScope.of(context).notification,
              builder: (context, _) => ForumPostList(
                postsLoading: _postsLoading,
                posts: _posts,
                isMember: forum.isMember,
                hasMorePosts: _hasMorePosts,
                currentUserId: auth.userId ?? '',
                isAdmin: auth.isAdmin,
                forumId: widget.id,
                unreadPostIds: AppScope.of(
                  context,
                ).notification.unreadPostIdsForForum(widget.id),
                onVote: _votePost,
                onDelete: _deletePost,
                onReport: _reportPost,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
