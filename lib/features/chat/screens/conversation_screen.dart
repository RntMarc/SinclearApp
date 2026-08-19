import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/chat_models.dart';
import '../widgets/conversation_body.dart';

/// Volle Konversations-Ansicht: Header mit Titel (inkl. Gruppenname) plus
/// den eingebetteten [ConversationBody].
class ConversationScreen extends StatelessWidget {
  final String conversationId;

  const ConversationScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return DesignSurface(
      child: ListenableBuilder(
        listenable: scope.chat,
        builder: (context, _) {
          final list = scope.chat.conversations;
          ChatConversation? conversation;
          for (final c in list) {
            if (c.id == conversationId) {
              conversation = c;
              break;
            }
          }
          final title = _resolveTitle(conversation);

          return Column(
            children: [
              DesignSubpageHeader(
                leading: DesignIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => context.pop(),
                ),
                title: title,
              ),
              Expanded(child: ConversationBody(conversationId: conversationId)),
            ],
          );
        },
      ),
    );
  }

  static String _resolveTitle(ChatConversation? conversation) {
    if (conversation == null) return 'Chat';
    if (conversation.otherUser?.displayName.isNotEmpty == true) {
      return conversation.otherUser!.displayName;
    }
    if (conversation.name?.isNotEmpty == true) return conversation.name!;
    return 'Chat';
  }
}
