import 'package:flutter/material.dart';
import '../../../core/utils/base64_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/forum_models.dart';

class ForumCard extends StatelessWidget {
  final Forum forum;
  final VoidCallback onTap;

  const ForumCard({super.key, required this.forum, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Row(
        children: [
          if (forum.image != null)
            Material(
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radiusSm),
                child: Image.memory(
                  decodeBase64Image(forum.image!),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallbackIcon(tokens),
                ),
              ),
            )
          else
            _fallbackIcon(tokens),
          SizedBox(width: tokens.spaceLg),
          Expanded(
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
                  SizedBox(height: tokens.spaceXs),
                  DesignText(
                    forum.description!,
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: tokens.spaceMd),
          Column(
            children: [
              Icon(Icons.people_rounded, size: 18, color: tokens.textLow),
              SizedBox(height: 2),
              DesignText(
                '${forum.memberCount}',
                style: DesignTextStyle.label,
                color: tokens.textLow,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon(DesignTokens tokens) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
      child: Icon(Icons.forum_rounded, color: tokens.primary),
    );
  }
}
