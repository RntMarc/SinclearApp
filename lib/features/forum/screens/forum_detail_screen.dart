import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/app_scope.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_forum == null && _loading) {
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
      MemberSheet.show(context, members: response.data);
    } catch (e) {
      developer.log('Failed to load members', error: e);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post löschen'),
        content: const Text('Möchtest du diesen Post wirklich löschen?'),
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
    final auth = AppScope.of(context).auth;

    return Scaffold(
      floatingActionButton: _forum?.isMember == true
          ? FloatingActionButton(
              onPressed: () => context.go('/forum/${widget.id}/erstellen'),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: _buildBody(context, auth),
    );
  }

  Widget _buildBody(BuildContext context, dynamic auth) {
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

    final forum = _forum!;
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              forum.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            background: forum.image != null
                ? Image.memory(
                    _decodeBase64(forum.image!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: theme.colorScheme.primaryContainer),
                  )
                : Container(
                    color: theme.colorScheme.primaryContainer,
                    child: Center(
                      child: Icon(
                        Icons.forum_rounded,
                        size: 48,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
          ),
          actions: [
            IconButton(
              onPressed: _showMembers,
              icon: Badge(
                label: Text('${forum.memberCount}'),
                child: const Icon(Icons.people_rounded),
              ),
              tooltip: 'Mitglieder',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'notifications') _toggleNotifications();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'notifications',
                  child: Row(
                    children: [
                      Icon(
                        forum.notificationsEnabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        forum.notificationsEnabled
                            ? 'Benachrichtigungen aus'
                            : 'Benachrichtigungen an',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (forum.description != null && forum.description!.isNotEmpty)
                  Text(
                    forum.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                const SizedBox(height: 16),
                if (forum.isMember)
                  FilledButton.tonalIcon(
                    onPressed: _toggleJoin,
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: const Text('Forum verlassen'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _toggleJoin,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Forum beitreten'),
                  ),
                const SizedBox(height: 16),
                const Divider(),
              ],
            ),
          ),
        ),
        if (_postsLoading && _posts.isEmpty)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_posts.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                forum.isMember
                    ? 'Noch keine Posts. Erstelle den ersten Beitrag!'
                    : 'Tritt dem Forum bei, um Posts zu sehen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == _posts.length) {
                  if (_hasMorePosts && !_postsLoading) {
                    _loadMorePosts();
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                final post = _posts[index];
                return PostCard(
                  post: post,
                  currentUserId: auth.userId ?? '',
                  onTap: () => context.go(
                    '/forum/${widget.id}/beitrag/${post.id}',
                  ),
                  onVote: () => _votePost(post),
                  onDelete: (post.userId == auth.userId || auth.isAdmin)
                      ? () => _deletePost(post)
                      : null,
                );
              },
              childCount: _posts.length + 1,
            ),
          ),
      ],
    );
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

  static Uint8List _decodeBase64(String base64String) {
    final cleaned = base64String.contains(',')
        ? base64String.split(',').last
        : base64String;
    return _base64Decode(cleaned);
  }

  static Uint8List _base64Decode(String s) {
    final padded = s.padRight(
      s.length + (4 - s.length % 4) % 4,
      '=',
    );
    return Uint8List.fromList(
      List<int>.generate(padded.length, (i) {
        const chars =
            'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        int val = 0;
        for (int j = 0; j < 4; j++) {
          final c = padded[i + j];
          if (c == '=') continue;
          val = (val << 6) | chars.indexOf(c);
        }
        return val >> 8 * (3 - i % 4);
      }).take(padded.length * 3 ~/ 4).toList(),
    );
  }
}
