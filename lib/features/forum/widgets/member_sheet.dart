import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/user_avatar.dart';
import '../models/forum_models.dart';

class MemberSheet extends StatelessWidget {
  final List<ForumMember> members;

  const MemberSheet({super.key, required this.members});

  static void show(BuildContext context, {required List<ForumMember> members}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MemberSheet(members: members),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxheight = MediaQuery.of(context).size.height * 0.5;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxheight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mitglieder (${members.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  leading: UserAvatar(
                    imageUrl: member.image,
                    displayName: member.displayName ?? '?',
                    radius: 20,
                  ),
                  title: Text(member.displayName ?? 'Unbekannt'),
                  trailing: member.notificationsEnabled
                      ? const Icon(
                          Icons.notifications_active_rounded,
                          size: 18,
                        )
                      : Icon(
                          Icons.notifications_off_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                        ),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/kontakte/${member.userId}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
