import 'package:flutter/material.dart';

import '../../../core/widgets/user_avatar.dart';

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
        UserAvatar(
          imageUrl: imageUrl,
          displayName: displayName,
          radius: avatarSize / 2,
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(displayName, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
