import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../models/forum_models.dart';

class MemberSheet extends StatelessWidget {
  final List<ForumMember> members;

  const MemberSheet({super.key, required this.members});

  static void show(BuildContext context, {required List<ForumMember> members}) {
    showDesignSheet(
      context: context,
      child: MemberSheet(members: members),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final maxheight = MediaQuery.of(context).size.height * 0.5;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxheight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'Mitglieder (${members.length})',
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return DesignListTile(
                  leading: DesignAvatar(
                    imageUrl: member.image,
                    name: member.displayName ?? '?',
                    size: 36,
                  ),
                  title: member.displayName ?? 'Unbekannt',
                  trailing: DesignIconButton(
                    icon: member.notificationsEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    onPressed: null,
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
