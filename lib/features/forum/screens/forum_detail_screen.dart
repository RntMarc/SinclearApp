import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/base64_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/forum_models.dart';
import '../widgets/member_sheet.dart';
import '../widgets/post_card.dart';

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
      _load();
    } catch (e) {
      developer.log('Join/leave failed', error: e);
    }
  }

  Future<void> _toggleNotifications() async {
    final forum = _forum;
    if (forum == null) return;
    try {
      final forumService = AppScope.of(context).forum;
      await forumService.setNotifications(
        forum.id,
        enabled: !forum.notificationsEnabled,
      );
      setState(() {
        _forum = ForumDetail(
          id: forum.id,
          name: forum.name,
          description: forum.description,
          image: forum.image,
          memberCount: forum.memberCount,
          createdAt: forum.createdAt,
          updatedAt: forum.updatedAt,
          isMember: forum.isMember,
          notificationsEnabled: !forum.notificationsEnabled,
        );
      });
    } catch (e) {
      developer.log('Notification toggle failed', error: e);
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
        SnackBar(content: Text('Mitglieder konnten nicht geladen werden.')),
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
      await forumService.deletePost(widget.id, post.id);
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

    return DesignSurface(
      child: Column(
        children: [
          DesignAppBar(
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
              DesignIconButton(
                icon: _forum?.notificationsEnabled == true
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                onPressed: _toggleNotifications,
              ),
            ],
          ),
          Expanded(
            child: _buildBody(context, tokens, auth),
          ),
          if (_forum?.isMember == true)
            Padding(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: DesignButton(
                variant: DesignButtonVariant.filled,
                icon: Icons.add_rounded,
                label: 'Neuer Beitrag',
                fullWidth: true,
                onPressed: () => context.go('/forum/${widget.id}/erstellen'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DesignTokens tokens,
    dynamic auth,
  ) {
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
            DesignText(_error!, style: DesignTextStyle.body, color: tokens.textHigh),
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
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.only(
          left: tokens.spaceLg,
          right: tokens.spaceLg,
          top: tokens.spaceSm,
          bottom: tokens.spaceXxl,
        ),
        children: [
          // Forum header card
          DesignCard(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (forum.image != null)
                  Material(
                    type: MaterialType.transparency,
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(tokens.radiusLg),
                      ),
                      child: Image.memory(
                        decodeBase64Image(forum.image!),
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 120,
                          color: tokens.primary.withValues(alpha: 0.15),
                          child: Center(
                            child: Icon(Icons.forum_rounded, size: 48, color: tokens.primary),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: tokens.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(tokens.radiusLg),
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.forum_rounded, size: 48, color: tokens.primary),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(tokens.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DesignText(
                        forum.name,
                        style: DesignTextStyle.subtitle,
                        color: tokens.textHigh,
                      ),
                      if (forum.description != null &&
                          forum.description!.isNotEmpty) ...[
                        SizedBox(height: tokens.spaceSm),
                        DesignText(
                          forum.description!,
                          style: DesignTextStyle.body,
                          color: tokens.textLow,
                        ),
                      ],
                      SizedBox(height: tokens.spaceLg),
                      DesignButton(
                        variant: forum.isMember
                            ? DesignButtonVariant.outlined
                            : DesignButtonVariant.filled,
                        icon: forum.isMember
                            ? Icons.exit_to_app_rounded
                            : Icons.add_rounded,
                        label: forum.isMember
                            ? 'Forum verlassen'
                            : 'Forum beitreten',
                        onPressed: _toggleJoin,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.spaceMd),
          const DesignDivider(),
          SizedBox(height: tokens.spaceMd),
          if (_postsLoading && _posts.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceXl),
                child: CircularProgressIndicator(color: tokens.primary),
              ),
            )
          else if (_posts.isEmpty)
            Center(
              child: DesignText(
                forum.isMember
                    ? 'Noch keine Posts. Erstelle den ersten Beitrag!'
                    : 'Tritt dem Forum bei, um Posts zu sehen.',
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
            )
          else ...[
            ...List.generate(_posts.length, (index) {
              final post = _posts[index];
              return Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceSm),
                child: PostCard(
                  key: ValueKey(post.id),
                  post: post,
                  currentUserId: auth.userId ?? '',
                  onTap: () => context.go('/forum/${widget.id}/beitrag/${post.id}'),
                  onVote: () => _votePost(post),
                  onDelete: (post.userId == auth.userId || auth.isAdmin)
                      ? () => _deletePost(post)
                      : null,
                ),
              );
            }),
            if (_hasMorePosts && _postsLoading)
              Padding(
                padding: EdgeInsets.all(tokens.spaceLg),
                child: Center(
                  child: CircularProgressIndicator(color: tokens.primary),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
