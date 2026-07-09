import 'package:flutter/material.dart';
import '../../../core/utils/base64_helper.dart';
import '../models/forum_models.dart';

class ForumCard extends StatelessWidget {
  final Forum forum;
  final VoidCallback onTap;

  const ForumCard({super.key, required this.forum, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (forum.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    decodeBase64Image(forum.image!),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _FallbackIcon(theme: theme),
                  ),
                )
              else
                _FallbackIcon(theme: theme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forum.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (forum.description != null &&
                        forum.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        forum.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Icon(
                    Icons.people_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${forum.memberCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _FallbackIcon extends StatelessWidget {
  final ThemeData theme;
  const _FallbackIcon({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.forum_rounded,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}
