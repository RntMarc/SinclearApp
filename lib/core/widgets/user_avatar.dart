import 'package:flutter/material.dart';

import '../image/image_provider_helper.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final double radius;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final provider = resolveImageProvider(imageUrl);
    return CircleAvatar(
      radius: radius,
      backgroundImage: provider,
      child: provider == null
          ? Text(
              displayName.isNotEmpty
                  ? displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : null,
    );
  }
}
