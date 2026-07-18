import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_divider.dart';
import '../../../design/widgets/composite/comment_input.dart';
import '../models/forum_models.dart';
import 'comment_tree.dart';

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

class PostVoteSection extends StatelessWidget {
  final bool hasVoted;
  final int upvoteCount;
  final VoidCallback? onVote;

  const PostVoteSection({
    super.key,
    required this.hasVoted,
    required this.upvoteCount,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Row(
      children: [
        GestureDetector(
          onTap: onVote,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasVoted
                    ? Icons.thumb_up_rounded
                    : Icons.thumb_up_outlined,
                size: 20,
                color: hasVoted ? tokens.primary : tokens.textLow,
              ),
              const SizedBox(width: 6),
              DesignText(
                '$upvoteCount',
                style: DesignTextStyle.label,
                color: hasVoted ? tokens.primary : tokens.textLow,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PostCommentsSection extends StatelessWidget {
  final int commentTotal;
  final String? replyToId;
  final bool commentsLoading;
  final List<FeedPostComment> comments;
  final String currentUserId;
  final bool isAdmin;
  final ValueChanged<String> onReply;
  final void Function(String text, {String? parentId}) onAddComment;
  final void Function(String commentId) onDeleteComment;
  final String Function(String userId) resolveUserName;

  const PostCommentsSection({
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
    required this.resolveUserName,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: tokens.spaceXl),
        const DesignDivider(),
        SizedBox(height: tokens.spaceMd),
        DesignText(
          'Kommentare ($commentTotal)',
          style: DesignTextStyle.subtitle,
          color: tokens.primary,
        ),
        SizedBox(height: tokens.spaceMd),
        if (replyToId == null)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceLg),
            child: CommentInput(
              hintText: 'Kommentar hinzufügen...',
              onSubmit: (text) => onAddComment(text),
            ),
          ),
        if (replyToId != null)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceLg),
            child: CommentInput(
              hintText: 'Antworten...',
              autofocus: true,
              onSubmit: (text) => onAddComment(text, parentId: replyToId),
              onCancel: () => onReply(''),
            ),
          ),
        if (commentsLoading)
          Center(child: CircularProgressIndicator(color: tokens.primary))
        else if (comments.isEmpty)
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
          ...comments.map(
            (comment) => CommentTreeTile(
              comment: comment,
              currentUserId: currentUserId,
              isAdmin: isAdmin,
              resolveUserName: resolveUserName,
              onReply: onReply,
              onDelete: onDeleteComment,
            ),
          ),
      ],
    );
  }
}
