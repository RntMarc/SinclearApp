import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../core/utils/spotify_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/comment_input.dart';
import '../models/forum_models.dart';
import 'youtube_player_embed.dart';
import 'spotify_thumbnail.dart';
import 'og_preview_card.dart';

IconData postTypeIcon(String type) {
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

String postTypeLabel(String type) {
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

List<Widget> postLinkDetailEntries(DesignTokens tokens, FeedPost post) {
  final links = post.type == 'video' || post.type == 'music'
      ? post.genericMusicUrls
      : post.type != 'web' && post.type != 'text'
      ? post.urls
      : const <MusicUrl>[];
  if (links.isEmpty) return const [];
  return [
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

class PostDetailCard extends StatelessWidget {
  final FeedPost post;
  final bool hasVoted;
  final int upvoteCount;
  final VoidCallback onVote;

  const PostDetailCard({
    super.key,
    required this.post,
    required this.hasVoted,
    required this.upvoteCount,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      margin: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(tokens),
          if (post.text != null && post.text!.isNotEmpty) ...[
            SizedBox(height: tokens.spaceMd),
            DesignText(
              post.text!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
          ],
          ..._buildMedia(tokens),
          ...postLinkDetailEntries(tokens, post),
          SizedBox(height: tokens.spaceLg),
          _buildVoteRow(tokens),
        ],
      ),
    );
  }

  Widget _buildHeader(DesignTokens tokens) {
    return Row(
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
        Icon(postTypeIcon(post.type), size: 16, color: tokens.primary),
        SizedBox(width: tokens.spaceXs),
        DesignText(
          postTypeLabel(post.type),
          style: DesignTextStyle.label,
          color: tokens.primary,
        ),
      ],
    );
  }

  List<Widget> _buildMedia(DesignTokens tokens) {
    final widgets = <Widget>[];

    if (post.type == 'web') {
      if (post.youtubeIds.isNotEmpty) {
        widgets.add(SizedBox(height: tokens.spaceMd));
        for (final id in post.youtubeIds) {
          widgets.add(
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceMd),
              child: DesignCard(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(tokens.radiusLg),
                  child: YouTubePlayerEmbed(videoId: id),
                ),
              ),
            ),
          );
        }
      }
      if (post.spotifyItems.isNotEmpty) {
        widgets.add(SizedBox(height: tokens.spaceMd));
        for (final item in post.spotifyItems) {
          widgets.add(
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceMd),
              child: SpotifyThumbnail(
                item: item,
                originalUrl: post.webUrls.firstWhere(
                  (u) => SpotifyHelper.parseUrl(u) != null,
                  orElse: () => post.webUrls.first,
                ),
              ),
            ),
          );
        }
      }
      if (post.genericUrls.isNotEmpty) {
        widgets.add(SizedBox(height: tokens.spaceMd));
        for (final url in post.genericUrls) {
          widgets.add(
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceMd),
              child: OgPreviewCard(url: url),
            ),
          );
        }
      }
    }

    if (post.type == 'video' && post.youtubeVideoIds.isNotEmpty) {
      widgets.add(SizedBox(height: tokens.spaceMd));
      for (final id in post.youtubeVideoIds) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceMd),
            child: DesignCard(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                child: YouTubePlayerEmbed(videoId: id),
              ),
            ),
          ),
        );
      }
    }

    if (post.type == 'music' && post.spotifyMusicItems.isNotEmpty) {
      widgets.add(SizedBox(height: tokens.spaceMd));
      for (final item in post.spotifyMusicItems) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceMd),
            child: SpotifyThumbnail(
              item: item,
              originalUrl: post.urls
                  .where((u) => u.platform.toLowerCase().contains('spotify'))
                  .first
                  .url,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildVoteRow(DesignTokens tokens) {
    return DesignButton(
      variant: hasVoted
          ? DesignButtonVariant.filled
          : DesignButtonVariant.outlined,
      icon: hasVoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
      label: '$upvoteCount',
      onPressed: onVote,
    );
  }
}

class PostCommentsCard extends StatelessWidget {
  final int commentTotal;
  final String? replyToId;
  final bool commentsLoading;
  final List<FeedPostComment> comments;
  final String currentUserId;
  final bool isAdmin;
  final ValueChanged<String> onReply;
  final void Function(String text, {String? parentId}) onAddComment;
  final void Function(String commentId) onDeleteComment;
  final void Function(String commentId)? onReportComment;

  const PostCommentsCard({
    super.key,
    required this.commentTotal,
    this.replyToId,
    required this.commentsLoading,
    required this.comments,
    required this.currentUserId,
    required this.isAdmin,
    required this.onReply,
    required this.onAddComment,
    required this.onDeleteComment,
    this.onReportComment,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      margin: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
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
                '$commentTotal',
                style: DesignTextStyle.label,
                color: tokens.textLow,
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMd),
          if (replyToId == null)
            CommentInput(
              hintText: 'Kommentar hinzufügen...',
              onSubmit: (text) => onAddComment(text),
            )
          else
            CommentInput(
              hintText: 'Antworten...',
              autofocus: true,
              onSubmit: (text) => onAddComment(text, parentId: replyToId),
              onCancel: () => onReply(''),
            ),
          if (commentsLoading) ...[
            SizedBox(height: tokens.spaceMd),
            Center(child: CircularProgressIndicator(color: tokens.primary)),
          ] else if (comments.isEmpty) ...[
            SizedBox(height: tokens.spaceLg),
            Center(
              child: DesignText(
                'Noch keine Kommentare.',
                style: DesignTextStyle.body,
                color: tokens.textLow,
              ),
            ),
          ] else ...[
            SizedBox(height: tokens.spaceMd),
            ...comments.map(
              (comment) => PostCommentTile(
                comment: comment,
                currentUserId: currentUserId,
                isAdmin: isAdmin,
                onReply: onReply,
                onDelete: onDeleteComment,
                onReport: onReportComment,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PostCommentTile extends StatelessWidget {
  final FeedPostComment comment;
  final String currentUserId;
  final bool isAdmin;
  final ValueChanged<String> onReply;
  final ValueChanged<String> onDelete;
  final ValueChanged<String>? onReport;

  const PostCommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.isAdmin,
    required this.onReply,
    required this.onDelete,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final isOwner = comment.userId == currentUserId;
    final userName = comment.userName ?? (isOwner ? 'Du' : 'Benutzer');

    return DesignCard(
      margin: EdgeInsets.only(bottom: tokens.spaceSm),
      padding: EdgeInsets.all(tokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(tokens, isOwner, userName, context),
          SizedBox(height: tokens.spaceXs),
          if (comment.isDeleted)
            DesignText(
              'Kommentar gelöscht',
              style: DesignTextStyle.body,
              color: tokens.textLow.withValues(alpha: 0.5),
            )
          else ...[
            DesignText(
              comment.text!,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            SizedBox(height: tokens.spaceXs),
            GestureDetector(
              onTap: () => onReply(comment.id),
              child: DesignText(
                'Antworten',
                style: DesignTextStyle.label,
                color: tokens.primary,
              ),
            ),
          ],
          if (comment.children.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: tokens.spaceLg,
                top: tokens.spaceSm,
              ),
              child: Column(
                children: comment.children
                    .map(
                      (child) => PostCommentTile(
                        comment: child,
                        currentUserId: currentUserId,
                        isAdmin: isAdmin,
                        onReply: onReply,
                        onDelete: onDelete,
                        onReport: onReport,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    DesignTokens tokens,
    bool isOwner,
    String userName,
    BuildContext context,
  ) {
    final adminOnly = isAdmin && !isOwner;
    return Row(
      children: [
        DesignAvatar(imageUrl: comment.userImage, name: userName, size: 20),
        SizedBox(width: tokens.spaceSm),
        DesignText(
          userName,
          style: DesignTextStyle.label,
          color: tokens.textHigh,
        ),
        SizedBox(width: tokens.spaceSm),
        DesignText(
          app_date.formatRelativeDate(comment.createdAt),
          style: DesignTextStyle.label,
          color: tokens.textLow.withValues(alpha: 0.6),
        ),
        const Spacer(),
        if (onReport != null && !comment.isDeleted)
          DesignIconButton(
            icon: Icons.flag_rounded,
            onPressed: () => onReport!(comment.id),
          ),
        if (isOwner || isAdmin)
          DesignIconButton(
            icon: Icons.more_vert_rounded,
            onPressed: () => _openMenu(context, adminOnly),
          ),
      ],
    );
  }

  void _openMenu(BuildContext context, bool adminOnly) {
    final tokens = DesignTheme.of(context);
    showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            adminOnly ? '👑 Kommentar löschen' : 'Kommentar löschen',
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          DesignText(
            'Kommentar wirklich löschen?',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceXl),
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
    ).then((confirmed) {
      if (confirmed == true) onDelete(comment.id);
    });
  }
}
