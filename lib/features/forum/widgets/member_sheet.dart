import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/base64_helper.dart';
import '../models/forum_models.dart';

class MemberSheet extends StatelessWidget {
  final List<ForumMember> members;

  const MemberSheet({super.key, required this.members});

  static void show(BuildContext context, {required List<ForumMember> members}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: true,
      builder: (context, scrollController) {
        return Column(
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
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: member.image != null
                        ? CircleAvatar(
                            backgroundImage: MemoryImage(
                              decodeBase64Image(member.image!),
                            ),
                          )
                        : CircleAvatar(
                            child: Text(
                              (member.displayName ?? '?').substring(0, 1),
                            ),
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
        );
      },
    );
  }

}
