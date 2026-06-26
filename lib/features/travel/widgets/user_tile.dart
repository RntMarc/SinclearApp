import 'package:flutter/cupertino.dart';

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
        ClipOval(
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: resolveImageProvider(imageUrl) != null
                ? Image(
                    image: resolveImageProvider(imageUrl)!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: avatarSize * 0.45,
                        fontWeight: FontWeight.w600,
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(displayName, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
