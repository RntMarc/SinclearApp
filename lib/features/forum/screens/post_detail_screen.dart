import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../core/utils/spotify_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_app_bar.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/forum_models.dart';
import '../widgets/comment_tree.dart';
import '../widgets/youtube_player_embed.dart';
import '../widgets/spotify_thumbnail.dart';
import '../widgets/og_preview_card.dart';

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
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'Kommentar löschen',
            style: DesignTextStyle.subtitle,
            color: DesignTheme.of(context).textHigh,
          ),
          SizedBox(height: DesignTheme.of(context).spaceMd),
          DesignText(
            'Kommentar wirklich löschen?',
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
    final tokens = DesignTheme.of(context);
    final auth = AppScope.of(context).auth;
    final isAdmin = auth.isAdmin;
    final currentUserId = auth.userId ?? '';

    return DesignSurface(
      child: Column(
        children: [
          DesignAppBar(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            title: _post?.title ?? 'Beitrag',
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
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator(color: tokens.primary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
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
            ),
          ],
        ),
      );
    }

    final post = _post!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(tokens.spaceLg),
        children: [
          Row(
            children: [
              DesignAvatar(
                imageUrl: post.userImage,
                name: post.userName ?? post.userId,
                size: 32,
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DesignText(
                      post.userName ?? 'Benutzer',
                      style: DesignTextStyle.label,
                      color: tokens.textHigh,
                    ),
                    DesignText(
                      app_date.formatRelativeDate(post.createdAt),
                      style: DesignTextStyle.label,
                      color: tokens.textLow.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              Icon(_typeIcon(post.type), size: 16, color: tokens.primary),
              SizedBox(width: tokens.spaceXs),
              DesignText(
                _typeLabel(post.type),
                style: DesignTextStyle.label,
                color: tokens.primary,
              ),
            ],
          ),
          if (post.title != null && post.title!.isNotEmpty) ...[
            SizedBox(height: tokens.spaceLg),
            DesignText(
              post.title!,
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
          ],
          if (post.text != null && post.text!.isNotEmpty) ...[
            SizedBox(height: tokens.spaceMd),
            DesignText(
              post.text!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
          ],
          if (post.type == 'web') ...[
            if (post.youtubeIds.isNotEmpty) ...[
              SizedBox(height: tokens.spaceLg),
              ...post.youtubeIds.map(
                (id) => Padding(
                  padding: EdgeInsets.only(bottom: tokens.spaceMd),
                  child: YouTubePlayerEmbed(videoId: id),
                ),
              ),
            ],
            if (post.spotifyItems.isNotEmpty) ...[
              SizedBox(height: tokens.spaceLg),
              ...post.spotifyItems.map(
                (SpotifyItem item) => Padding(
                  padding: EdgeInsets.only(bottom: tokens.spaceMd),
                  child: SpotifyThumbnail(
                    item: item,
                    originalUrl: post.webUrls.firstWhere(
                      (u) => SpotifyHelper.parseUrl(u) != null,
                      orElse: () => post.webUrls.first,
                    ),
                  ),
                ),
              ),
            ],
            if (post.genericUrls.isNotEmpty) ...[
              SizedBox(height: tokens.spaceLg),
              ...post.genericUrls.map(
                (url) => Padding(
                  padding: EdgeInsets.only(bottom: tokens.spaceMd),
                  child: OgPreviewCard(url: url),
                ),
              ),
            ],
          ],
          if (post.type == 'video' && post.youtubeVideoIds.isNotEmpty) ...[
            SizedBox(height: tokens.spaceLg),
            ...post.youtubeVideoIds.map(
              (id) => Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceMd),
                child: YouTubePlayerEmbed(videoId: id),
              ),
            ),
          ],
          if (post.type == 'music' && post.spotifyMusicItems.isNotEmpty) ...[
            SizedBox(height: tokens.spaceLg),
            ...post.spotifyMusicItems.map(
              (SpotifyItem item) => Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceMd),
                child: SpotifyThumbnail(
                  item: item,
                  originalUrl: post.urls
                      .firstWhere(
                        (u) => u.platform.toLowerCase().contains('spotify'),
                      )
                      .url,
                ),
              ),
            ),
          ],
          ..._linkDetailEntries(tokens, post),
          SizedBox(height: tokens.spaceXl),
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
                        userName: post.userName,
                        userImage: post.userImage,
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
                          ? tokens.primary
                          : tokens.textLow,
                    ),
                    SizedBox(width: 6),
                    DesignText(
                      '${post.upvoteCount}',
                      style: DesignTextStyle.label,
                      color: post.hasVoted
                          ? tokens.primary
                          : tokens.textLow,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceXl),
          const DesignDivider(),
          SizedBox(height: tokens.spaceMd),
          DesignText(
            'Kommentare ($_commentTotal)',
            style: DesignTextStyle.subtitle,
            color: tokens.primary,
          ),
          SizedBox(height: tokens.spaceMd),
          if (_replyToId == null)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceLg),
              child: CommentInput(
                hintText: 'Kommentar hinzufügen...',
                onSubmit: (text) => _addComment(text),
              ),
            ),
          if (_replyToId != null)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceLg),
              child: CommentInput(
                hintText: 'Antworten...',
                autofocus: true,
                onSubmit: (text) => _addComment(text, parentId: _replyToId),
                onCancel: () => setState(() => _replyToId = null),
              ),
            ),
          if (_commentsLoading)
            Center(child: CircularProgressIndicator(color: tokens.primary))
          else if (_comments.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceLg),
              child: Center(
                child: DesignText(
                  'Noch keine Kommentare.',
                  style: DesignTextStyle.body,
                  color: tokens.textLow,
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

  List<Widget> _linkDetailEntries(DesignTokens tokens, FeedPost post) {
    final links = post.type == 'video' || post.type == 'music'
        ? post.genericMusicUrls
        : post.type != 'web' && post.type != 'text'
            ? post.urls
            : const <MusicUrl>[];
    if (links.isEmpty) return const [];
    return [
      SizedBox(height: tokens.spaceLg),
      ...links.map(
        (url) => Padding(
          padding: EdgeInsets.only(bottom: tokens.spaceSm),
          child: GestureDetector(
            onTap: () => launchUrl(Uri.parse(url.url)),
            child: DesignCard(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.all(tokens.spaceMd),
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: tokens.primary,
                  ),
                  SizedBox(width: tokens.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DesignText(
                          url.platform.toUpperCase(),
                          style: DesignTextStyle.label,
                          color: tokens.primary,
                        ),
                        DesignText(
                          Uri.tryParse(url.url)?.host ?? url.url,
                          style: DesignTextStyle.label,
                          color: tokens.textLow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    ];
  }
}
