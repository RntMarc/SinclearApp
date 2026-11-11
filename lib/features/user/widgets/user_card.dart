import 'package:flutter/material.dart';
import '../../../design/widgets/composite/design_user_card.dart';
import '../models/user_models.dart';

/// Feature adapter that maps a [UserBasePublic] onto the catalog [DesignUserCard].
class UserCard extends StatelessWidget {
  final UserBasePublic user;
  final bool isSelf;
  final bool isCloseFriend;
  final VoidCallback onTap;
  final VoidCallback? onToggleCloseFriend;

  const UserCard({
    super.key,
    required this.user,
    required this.isSelf,
    this.isCloseFriend = false,
    required this.onTap,
    this.onToggleCloseFriend,
  });

  @override
  Widget build(BuildContext context) {
    return DesignUserCard(
      imageUrl: user.image,
      name: user.displayName,
      isSelf: isSelf,
      isCloseFriend: isCloseFriend,
      onToggleCloseFriend: onToggleCloseFriend,
      onTap: onTap,
    );
  }
}
