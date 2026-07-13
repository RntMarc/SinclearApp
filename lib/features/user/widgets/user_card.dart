import 'package:flutter/material.dart';
import '../../../design/widgets/composite/design_user_card.dart';
import '../models/user_models.dart';

/// Feature adapter that maps a [UserBasePublic] onto the catalog [DesignUserCard].
class UserCard extends StatelessWidget {
  final UserBasePublic user;
  final bool isSelf;
  final VoidCallback onTap;

  const UserCard({
    super.key,
    required this.user,
    required this.isSelf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DesignUserCard(
      imageUrl: user.image,
      name: user.displayName,
      subtitle: user.email,
      isSelf: isSelf,
      onTap: onTap,
    );
  }
}
