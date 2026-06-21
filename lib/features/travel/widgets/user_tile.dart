import 'package:flutter/material.dart';

import '../../../core/image/image_provider_helper.dart';

class UserTile extends StatelessWidget {
  final String displayName;
  final String? imageUrl;
  final double avatarSize;

  const UserTile({
    super.key,
    required this.displayName,
    this.imageUrl,
    this.avatarSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: avatarSize / 2,
          backgroundImage: resolveImageProvider(imageUrl),
          child: resolveImageProvider(imageUrl) == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: avatarSize * 0.45,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(displayName, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
