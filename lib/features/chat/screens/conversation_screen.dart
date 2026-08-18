import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_chat_composer.dart';
import '../../../design/widgets/composite/design_message_bubble.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../forum/widgets/og_preview_card.dart';
import '../models/chat_models.dart';

/// Konversations-Ansicht: Nachrichtenverlauf mit Live-Sync, Composer und
/// Read-Marking (Chat-Lesestand + zugehörige Benachrichtigungen).
class ConversationScreen extends StatefulWidget {
  final String conversationId;

  const ConversationScreen({super.key, required this.conversationId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  static final _urlPattern = RegExp(r'https?://[^\s]+');

  final ScrollController _scroll = ScrollController();
  ChatConversation? _conversation;
  bool _loading = true;
  String? _error;
  bool _sending = false;
  AppScope? _scope;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _scope = AppScope.of(context);
    _scope!.chat
      ..registerActive()
      ..setActiveConversation(widget.conversationId);
    _scroll.addListener(_maybeMarkRead);
    _scope!.chat.addListener(_onChatChanged);
    _load();
  }

  @override
  void dispose() {
    _scope?.chat.removeListener(_onChatChanged);
    _scope?.chat.setActiveConversation(null);
    _scope?.chat.unregisterActive();
    _scroll.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    // Nach neuen Nachrichten prüfen: unten angekommen → gelesen markieren.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeMarkRead());
  }

  Future<void> _load() async {
    final scope = _scope;
    if (scope == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await scope.chat.getMessages(widget.conversationId);
      final conversation = await scope.chat.loadConversation(
        widget.conversationId,
      );
      if (!mounted) return;
      setState(() {
        _conversation = conversation;
        _loading = false;
      });
      await _markRead();
    } catch (e, st) {
      developer.log(
        'Loading conversation failed',
        error: e,
        stackTrace: st,
        name: 'chat_screen',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Konversation konnte nicht geladen werden.';
      });
    }
  }

  /// Setzt Chat-Lesestand und markiert die Benachrichtigungen dieser
  /// Konversation als gelesen.
  Future<void> _markRead() async {
    final scope = _scope;
    if (scope == null) return;
    await scope.chat.markConversationRead(widget.conversationId);
    final ids = scope.notification.unreadIdsForConversation(
      widget.conversationId,
    );
    if (ids.isNotEmpty) {
      try {
        await scope.notification.markRead(
          ids,
          token: await scope.auth.getAccessToken(),
        );
      } catch (e, st) {
        developer.log(
          'markRead failed',
          error: e,
          stackTrace: st,
          name: 'chat_screen',
        );
      }
    }
  }

  void _maybeMarkRead() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 40) {
      unawaited(_markRead());
    }
  }

  Future<void> _send(String text) async {
    final scope = _scope;
    if (scope == null) return;
    setState(() => _sending = true);
    try {
      await scope.chat.sendMessage(widget.conversationId, text);
      _maybeMarkRead();
    } catch (e, st) {
      developer.log(
        'Sending message failed',
        error: e,
        stackTrace: st,
        name: 'chat_screen',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: DesignText(
            'Senden fehlgeschlagen. Bitte erneut versuchen.',
            color: DesignTheme.of(context).textOnPrimary,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final tokens = DesignTheme.of(context);

    final list = scope.chat.conversations;
    ChatConversation? conversation;
    for (final c in list) {
      if (c.id == widget.conversationId) {
        conversation = c;
        break;
      }
    }
    conversation ??= _conversation;

    final messages = scope.chat.messagesOf(widget.conversationId);
    final title = conversation?.otherUser?.displayName.isNotEmpty == true
        ? conversation!.otherUser!.displayName
        : 'Chat';

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: title,
          ),
          Expanded(child: _buildBody(tokens, conversation, messages)),
        ],
      ),
    );
  }

  Widget _buildBody(
    DesignTokens tokens,
    ChatConversation? conversation,
    List<DirectMessage>? messages,
  ) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: tokens.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesignText(_error!, style: DesignTextStyle.body),
            SizedBox(height: tokens.spaceMd),
            DesignButton(
              label: 'Erneut versuchen',
              variant: DesignButtonVariant.outlined,
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    final userId = _scope?.auth.userId;
    final allMessages = messages ?? const <DirectMessage>[];

    return Column(
      children: [
        Expanded(
          child: allMessages.isEmpty
              ? Center(
                  child: DesignText(
                    'Noch keine Nachrichten. Schreib die erste!',
                    style: DesignTextStyle.body,
                    color: tokens.textLow,
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceLg,
                    vertical: tokens.spaceMd,
                  ),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final message = allMessages[allMessages.length - 1 - index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceMd),
                      child: DesignMessageBubble(
                        text: message.content,
                        isOwn: message.senderId == userId,
                        time: message.createdAt,
                        deleted: message.deleted,
                        edited: message.editedAt != null,
                        linkPreview: _linkPreview(message),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceXs,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
          child: DesignChatComposer(sending: _sending, onSend: _send),
        ),
      ],
    );
  }

  /// URL-Vorschau (wie im Forum) für die erste URL im Nachrichtentext.
  Widget? _linkPreview(DirectMessage message) {
    if (message.deleted || message.type != 'text') return null;
    final match = _urlPattern.firstMatch(message.content);
    if (match == null) return null;
    return OgPreviewCard(url: match.group(0)!);
  }
}
