import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';

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
    final tokens = DesignTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DesignAvatar(
          imageUrl: imageUrl,
          name: displayName,
          size: avatarSize,
        ),
        SizedBox(width: tokens.spaceSm),
        Flexible(
          child: DesignText(
            displayName,
            style: DesignTextStyle.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
