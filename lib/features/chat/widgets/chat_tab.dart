import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_conversation_tile.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import 'new_chat_sheet.dart';

/// Chat-Reiter im Home-Screen: Konversationsliste mit Unread-Badges.
///
/// Hält den Sync-Loop des [ChatService] aktiv, solange der Tab sichtbar
/// ist, und aktualisiert die Unread-Registry beim Öffnen.
class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  AppScope? _scope;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _scope = AppScope.of(context);
    _scope!.chat.registerActive();
    unawaited(_load());
  }

  @override
  void dispose() {
    _scope?.chat.unregisterActive();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    final scope = _scope;
    if (scope == null) return;
    try {
      await scope.chat.refreshConversations(force: force);
      await scope.notification.refreshUnread(
        token: await scope.auth.getAccessToken(),
      );
    } catch (e, st) {
      developer.log(
        'ChatTab load failed',
        error: e,
        stackTrace: st,
        name: 'chat_tab',
      );
    }
  }

  void _openNewChat() {
    final scope = _scope;
    if (scope == null) return;
    showDesignSheet(context: context, child: const NewChatSheet());
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final tokens = DesignTheme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.chat, scope.notification]),
      builder: (context, _) {
        final conversations = scope.chat.conversations;
        return Column(
          children: [
            _ChatHeader(onNewChat: _openNewChat),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(force: true),
                child: conversations.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.only(top: tokens.spaceSm),
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          final other = conversation.otherUser;
                          final typing =
                              scope
                                  .chat
                                  .typingUsers[conversation.id]
                                  ?.isNotEmpty ==
                              true;
                          return DesignConversationTile(
                            name: other?.displayName.isNotEmpty == true
                                ? other!.displayName
                                : 'Unbekannt',
                            avatarUrl: other?.avatar,
                            lastMessage:
                                conversation.lastMessage?.deleted == true
                                ? 'Nachricht gelöscht'
                                : conversation.lastMessage?.content,
                            lastMessageAt: conversation.lastMessage?.createdAt,
                            unreadCount: conversation.unreadCount,
                            isTyping: typing,
                            onTap: () =>
                                context.push('/chat/${conversation.id}'),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Kopfzeile des Chat-Tabs: Titel plus Button für eine neue Unterhaltung.
class _ChatHeader extends StatelessWidget {
  final VoidCallback onNewChat;

  const _ChatHeader({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceMd,
        tokens.spaceMd,
        tokens.spaceXs,
      ),
      child: Row(
        children: [
          Expanded(
            child: DesignText(
              'Nachrichten',
              style: DesignTextStyle.title,
              color: tokens.textHigh,
            ),
          ),
          DesignIconButton(
            icon: Icons.edit_rounded,
            tinted: true,
            onPressed: onNewChat,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: EdgeInsets.all(tokens.spaceXl),
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: tokens.textLow,
              ),
              SizedBox(height: tokens.spaceMd),
              const DesignText(
                'Noch keine Nachrichten',
                style: DesignTextStyle.subtitle,
              ),
              SizedBox(height: tokens.spaceSm),
              DesignText(
                'Tippe auf das Stift-Symbol, um eine '
                'Unterhaltung zu starten.',
                style: DesignTextStyle.body,
                color: tokens.textLow,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
