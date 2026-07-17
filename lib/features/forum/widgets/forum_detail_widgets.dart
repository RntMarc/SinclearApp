import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/base64_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/forum_models.dart';
import 'post_card.dart';

class ForumHeaderCard extends StatelessWidget {
  final ForumDetail forum;
  final VoidCallback onToggleJoin;

  const ForumHeaderCard({
    super.key,
    required this.forum,
    required this.onToggleJoin,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
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
                if (forum.description != null && forum.description!.isNotEmpty) ...[
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
                  onPressed: onToggleJoin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ForumPostList extends StatelessWidget {
  final bool postsLoading;
  final List<FeedPost> posts;
  final bool isMember;
  final bool hasMorePosts;
  final String currentUserId;
  final bool isAdmin;
  final String forumId;
  final void Function(FeedPost post) onVote;
  final void Function(FeedPost post) onDelete;

  const ForumPostList({
    super.key,
    required this.postsLoading,
    required this.posts,
    required this.isMember,
    required this.hasMorePosts,
    required this.currentUserId,
    required this.isAdmin,
    required this.forumId,
    required this.onVote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    if (postsLoading && posts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceXl),
          child: CircularProgressIndicator(color: tokens.primary),
        ),
      );
    }

    if (posts.isEmpty) {
      return Center(
        child: DesignText(
          isMember
              ? 'Noch keine Posts. Erstelle den ersten Beitrag!'
              : 'Tritt dem Forum bei, um Posts zu sehen.',
          style: DesignTextStyle.body,
          color: tokens.textLow,
        ),
      );
    }

    return Column(
      children: [
        ...List.generate(posts.length, (index) {
          final post = posts[index];
          return Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSm),
            child: PostCard(
              key: ValueKey(post.id),
              post: post,
              currentUserId: currentUserId,
              onTap: () =>
                  context.go('/forum/$forumId/beitrag/${post.id}'),
              onVote: () => onVote(post),
              onDelete: (post.userId == currentUserId || isAdmin)
                  ? () => onDelete(post)
                  : null,
            ),
          );
        }),
        if (hasMorePosts && postsLoading)
          Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: Center(
              child: CircularProgressIndicator(color: tokens.primary),
            ),
          ),
      ],
    );
  }
}
