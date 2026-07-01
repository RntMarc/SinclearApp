import 'dart:typed_data';
import 'package:flutter/material.dart';
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
                    _decodeBase64(forum.image!),
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
