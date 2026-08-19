import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_chat_composer.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_message_bubble.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../forum/widgets/og_preview_card.dart';
import '../../moderation/models/moderation_models.dart';
import '../../moderation/widgets/moderation_request_sheet.dart';
import '../models/chat_models.dart';

/// Konversations-Ansicht: Nachrichtenverlauf mit Live-Sync, Composer,
/// Read-Marking, Edit/Delete, Tippindikator und lastSeenAt.
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
  DirectMessage? _editingMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _scope = AppScope.of(context);
    _scope!.chat.registerActive();
    _scroll.addListener(_maybeMarkRead);
    _scope!.chat.addListener(_onChatChanged);
    _load();
  }

  @override
  void dispose() {
    _scope?.chat.removeListener(_onChatChanged);
    _scope?.chat.unregisterActive();
    _scroll.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeMarkRead();
      // Konversation aus dem Service-State aktualisieren.
      final list = _scope?.chat.conversations;
      if (list != null) {
        for (final c in list) {
          if (c.id == widget.conversationId) {
            if (mounted) setState(() => _conversation = c);
            break;
          }
        }
      }
    });
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

  // ─── Senden / Bearbeiten ──────────────────────────────────────────────

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

  void _startEdit(DirectMessage message) {
    setState(() => _editingMessage = message);
  }

  void _cancelEdit() {
    setState(() => _editingMessage = null);
  }

  Future<void> _submitEdit(String newContent) async {
    final scope = _scope;
    final msg = _editingMessage;
    if (scope == null || msg == null) return;
    setState(() {
      _editingMessage = null;
      _sending = true;
    });
    try {
      await scope.chat.editMessage(widget.conversationId, msg.id, newContent);
    } catch (e, st) {
      developer.log(
        'Editing message failed',
        error: e,
        stackTrace: st,
        name: 'chat_screen',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: DesignText(
            'Bearbeitung fehlgeschlagen. Bitte erneut versuchen.',
            color: DesignTheme.of(context).textOnPrimary,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ─── Löschen ──────────────────────────────────────────────────────────

  Future<void> _confirmDelete(DirectMessage message) async {
    final tokens = DesignTheme.of(context);
    final confirmed = await showDesignSheet<bool>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'Nachricht löschen?',
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          DesignText(
            'Diese Nachricht wird für alle gelöscht.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceLg),
          Row(
            children: [
              Expanded(
                child: DesignButton(
                  variant: DesignButtonVariant.outlined,
                  label: 'Abbrechen',
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignButton(
                  variant: DesignButtonVariant.filled,
                  label: 'Löschen',
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _scope?.chat.deleteMessage(widget.conversationId, message.id);
    }
  }

  // ─── Melden / Kopieren ────────────────────────────────────────────────

  void _reportMessage(DirectMessage message) {
    showModerationRequestSheet(
      context,
      objectType: ModerationObjectType.chatMessage,
      objectId: message.id,
      objectName: message.content.isNotEmpty ? message.content : 'Nachricht',
      isOwn: message.senderId == _scope?.auth.userId,
    );
  }

  void _copyMessage(DirectMessage message) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DesignText(
          'Nachricht kopiert.',
          color: DesignTheme.of(context).textOnPrimary,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Long-Press-Menü ──────────────────────────────────────────────────

  void _showMessageActions(DirectMessage message) {
    final isOwn = message.senderId == _scope?.auth.userId;
    final tokens = DesignTheme.of(context);
    showDesignSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOwn && !message.deleted) ...[
            DesignListTile(
              leading: Icon(Icons.edit_rounded, color: tokens.textHigh),
              title: 'Bearbeiten',
              onTap: () {
                Navigator.pop(context);
                _startEdit(message);
              },
            ),
            DesignListTile(
              leading: Icon(Icons.delete_rounded, color: tokens.danger),
              title: 'Löschen',
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(message);
              },
            ),
          ],
          if (!message.deleted && message.content.isNotEmpty)
            DesignListTile(
              leading: Icon(Icons.content_copy_rounded, color: tokens.textHigh),
              title: 'Kopieren',
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message);
              },
            ),
          DesignListTile(
            leading: Icon(Icons.flag_rounded, color: tokens.warning),
            title: 'Melden',
            onTap: () {
              Navigator.pop(context);
              _reportMessage(message);
            },
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────

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

    // Tipp-Indikator
    final typingUsers = scope.chat.typingUsers[widget.conversationId] ?? [];
    final otherUserId = conversation?.otherUser?.id;
    final isTyping = otherUserId != null && typingUsers.contains(otherUserId);

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
          // lastSeenAt + Typing-Indikator
          _buildStatusRow(conversation, isTyping, tokens),
          Expanded(child: _buildBody(tokens, conversation, messages)),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    ChatConversation? conversation,
    bool isTyping,
    DesignTokens tokens,
  ) {
    final lastSeen = conversation?.lastSeenAt;
    if (!isTyping && lastSeen == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceXs,
      ),
      child: isTyping
          ? DesignText(
              'schreibt...',
              style: DesignTextStyle.label,
              color: tokens.primary,
            )
          : DesignText(
              'zuletzt online ${_relativeTime(lastSeen!)}',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.isNegative) return 'gerade eben';
    if (diff.inMinutes < 1) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    return app_date.formatDate(dt);
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
    final otherLastReadSeq = conversation?.otherLastReadSeq ?? 0;

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
                    final isOwn = message.senderId == userId;
                    return Padding(
                      padding: EdgeInsets.only(bottom: tokens.spaceMd),
                      child: DesignMessageBubble(
                        text: message.content,
                        isOwn: isOwn,
                        time: message.createdAt,
                        deleted: message.deleted,
                        edited: message.editedAt != null,
                        read: isOwn && message.seq <= otherLastReadSeq,
                        linkPreview: _linkPreview(message),
                        onLongPress: () => _showMessageActions(message),
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
          child: DesignChatComposer(
            sending: _sending,
            onSend: _editingMessage != null ? _submitEdit : _send,
            editInitialText: _editingMessage?.content,
            editLabel: _editingMessage != null ? 'Nachricht bearbeiten' : null,
            onCancelEdit: _editingMessage != null ? _cancelEdit : null,
            onTyping: () {
              _scope?.chat.sendTyping(widget.conversationId);
            },
          ),
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
