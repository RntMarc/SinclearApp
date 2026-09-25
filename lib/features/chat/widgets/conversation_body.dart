import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_chat_composer.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_message_bubble.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../forum/widgets/og_preview_card.dart';
import '../../moderation/models/moderation_models.dart';
import '../../moderation/widgets/moderation_request_sheet.dart';
import '../models/chat_models.dart';

final _log = Logger('chat.ui');

/// Eingebettete Konversations-Ansicht: Nachrichtenverlauf mit Live-Sync,
/// Composer, Read-Marking, Edit/Delete, Tippindikator und Online-Status.
///
/// Wird in [TripDetailScreen] und [TravelEventDetailScreen] als Chat-Tab
/// verwendet, sowie als Basis für den eigenen [ConversationScreen].
class ConversationBody extends StatefulWidget {
  final String conversationId;

  const ConversationBody({super.key, required this.conversationId});

  @override
  State<ConversationBody> createState() => _ConversationBodyState();
}

class _ConversationBodyState extends State<ConversationBody> {
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
    _scope!.chat.watchConversation(widget.conversationId);
    _scroll.addListener(_maybeMarkRead);
    _scope!.chat.addListener(_onChatChanged);
    _load();
  }

  @override
  void dispose() {
    _scope?.chat.removeListener(_onChatChanged);
    _scope?.chat.unwatchConversation(widget.conversationId);
    _scope?.chat.unregisterActive();
    _scroll.dispose();
    super.dispose();
  }

  void _onChatChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeMarkRead();
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
      _log.severe('Loading conversation failed', e, st);
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
        _log.warning('markRead failed', e, st);
      }
    }
  }

  void _maybeMarkRead() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    // reverse: true → pixels=0 ist unten (neueste Nachrichten).
    // Nutzer ist "unten" wenn pixels <= 200 (nahe am unteren Rand).
    if (position.pixels <= 200) {
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
      _log.warning('Sending message failed', e, st);
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
      _log.warning('Editing message failed', e, st);
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
    final tilePadding = EdgeInsets.symmetric(vertical: tokens.spaceSm);

    showDesignSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!message.deleted) ...[
            _reactionQuickRow(message, tokens),
            SizedBox(height: tokens.spaceSm),
          ],
          if (isOwn && !message.deleted) ...[
            DesignListTile(
              leading: Icon(Icons.edit_rounded, color: tokens.textHigh),
              title: 'Bearbeiten',
              padding: tilePadding,
              onTap: () {
                Navigator.pop(context);
                _startEdit(message);
              },
            ),
            DesignListTile(
              leading: Icon(Icons.delete_rounded, color: tokens.danger),
              title: 'Löschen',
              padding: tilePadding,
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
              padding: tilePadding,
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message);
              },
            ),
          if (message.reactions.isNotEmpty)
            DesignListTile(
              leading: Icon(Icons.groups_rounded, color: tokens.textHigh),
              title: 'Reaktionen anzeigen',
              padding: tilePadding,
              onTap: () {
                Navigator.pop(context);
                _showReactionUsers(message);
              },
            ),
          DesignListTile(
            leading: Icon(Icons.flag_rounded, color: tokens.warning),
            title: 'Melden',
            padding: tilePadding,
            onTap: () {
              Navigator.pop(context);
              _reportMessage(message);
            },
          ),
        ],
      ),
    );
  }

  /// Kompakte Emoji-Reihe im Long-Press-Menü; ein Tipp toggelt die Reaktion.
  Widget _reactionQuickRow(DirectMessage message, DesignTokens tokens) {
    final userId = _scope?.auth.userId;
    return Wrap(
      spacing: tokens.spaceSm,
      runSpacing: tokens.spaceSm,
      alignment: WrapAlignment.center,
      children: [
        for (final emoji in kReactionEmojis)
          DesignChip(
            label: emoji,
            selected: message.reactions.any(
              (r) => r.emoji == emoji && r.isMine(userId),
            ),
            onTap: () {
              Navigator.pop(context);
              _toggleReaction(message, emoji);
            },
          ),
      ],
    );
  }

  Future<void> _toggleReaction(DirectMessage message, String emoji) async {
    final scope = _scope;
    if (scope == null) return;
    try {
      await scope.chat.toggleReaction(widget.conversationId, message, emoji);
    } catch (e, st) {
      _log.warning('Reaction failed', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: DesignText(
            'Reaktion fehlgeschlagen. Bitte erneut versuchen.',
            color: DesignTheme.of(context).textOnPrimary,
          ),
        ),
      );
    }
  }

  /// Zeigt, wer mit welchem Emoji reagiert hat (gruppiert nach Emoji).
  void _showReactionUsers(DirectMessage message) {
    final tokens = DesignTheme.of(context);
    final userId = _scope?.auth.userId;
    showDesignSheet(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            'Reaktionen',
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          for (final reaction in message.reactions) ...[
            DesignText(
              reaction.count > 1
                  ? '${reaction.emoji} ${reaction.count}'
                  : reaction.emoji,
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
            for (final user in reaction.users)
              DesignListTile(
                leading: DesignAvatar(
                  imageUrl: user.avatar,
                  name: user.displayName,
                ),
                title: user.displayName.isEmpty ? 'Unbekannt' : user.displayName,
                subtitle: user.id == userId ? 'Das bist du' : null,
                padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
              ),
            SizedBox(height: tokens.spaceSm),
          ],
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

    final typingUsers = scope.chat.typingUsers[widget.conversationId] ?? [];
    // _applyTyping filtert den eigenen Nutzer bereits heraus.
    final isTyping = typingUsers.isNotEmpty;

    return Column(
      children: [
        _buildStatusRow(conversation, isTyping, tokens),
        Expanded(child: _buildBody(tokens, conversation, messages)),
      ],
    );
  }

  Widget _buildStatusRow(
    ChatConversation? conversation,
    bool isTyping,
    DesignTokens tokens,
  ) {
    if (conversation == null) return const SizedBox.shrink();
    final scope = _scope;
    final isGroup = conversation.type == 'group';
    String? label;
    var color = tokens.textLow;

    if (isTyping) {
      return _TypingIndicator(tokens: tokens);
    } else if (isGroup) {
      final total = conversation.memberCount;
      if (total != null) {
        final online = scope?.chat.presentCount(conversation.id) ?? 0;
        label = '$online von $total online';
      }
    } else {
      final otherId = conversation.otherUser?.id;
      final online =
          otherId != null &&
          scope != null &&
          scope.chat.isPresent(conversation.id, otherId);
      if (online == true) {
        label = 'online';
        color = tokens.success;
      } else {
        final seen =
            (otherId != null ? scope?.chat.lastSeenAt(otherId) : null) ??
            conversation.lastSeenAt;
        if (seen != null) label = 'zuletzt online ${_relativeTime(seen)}';
      }
    }

    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceXs,
      ),
      child: DesignText(label, style: DesignTextStyle.label, color: color),
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
    final isGroup = conversation?.type == 'group';

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
                        reactions: [
                          for (final r in message.reactions)
                            DesignReaction(
                              emoji: r.emoji,
                              count: r.count,
                              selected: r.isMine(userId),
                            ),
                        ],
                        onReactionTap: message.deleted
                            ? null
                            : (emoji) => _toggleReaction(message, emoji),
                        senderName: isGroup && !isOwn
                            ? message.sender.displayName.isNotEmpty
                                  ? message.sender.displayName
                                  : null
                            : null,
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

  Widget? _linkPreview(DirectMessage message) {
    if (message.deleted || message.type != 'text') return null;
    final match = _urlPattern.firstMatch(message.content);
    if (match == null) return null;
    return OgPreviewCard(url: match.group(0)!);
  }
}

/// Animierter Typing-Indikator: "schreibt..." mit pulsierenden Punkten.
class _TypingIndicator extends StatefulWidget {
  final DesignTokens tokens;

  const _TypingIndicator({required this.tokens});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    if (MediaQuery.of(context).disableAnimations) {
      return _buildStatic(tokens);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _buildAnimated(tokens, _controller.value),
    );
  }

  Widget _buildStatic(DesignTokens tokens) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceXs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'schreibt',
            style: DesignTextStyle.label,
            color: tokens.primary,
          ),
          SizedBox(width: tokens.spaceXs),
          _Dot(color: tokens.primary, opacity: 1.0),
          SizedBox(width: tokens.spaceXs / 2),
          _Dot(color: tokens.primary, opacity: 1.0),
          SizedBox(width: tokens.spaceXs / 2),
          _Dot(color: tokens.primary, opacity: 1.0),
        ],
      ),
    );
  }

  Widget _buildAnimated(DesignTokens tokens, double progress) {
    // Drei Punkte mit versetzter Animation
    final double phase1 = (progress * 3) % 1.0;
    final double phase2 = ((progress + 0.33) * 3) % 1.0;
    final double phase3 = ((progress + 0.66) * 3) % 1.0;

    double opacity(double phase) {
      // Pulsiert zwischen 0.3 und 1.0
      return 0.3 + 0.7 * (0.5 - (phase - 0.5).abs());
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.tokens.spaceLg,
        vertical: widget.tokens.spaceXs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DesignText(
            'schreibt',
            style: DesignTextStyle.label,
            color: widget.tokens.primary,
          ),
          SizedBox(width: widget.tokens.spaceXs),
          _Dot(color: widget.tokens.primary, opacity: opacity(phase1)),
          SizedBox(width: widget.tokens.spaceXs / 2),
          _Dot(color: widget.tokens.primary, opacity: opacity(phase2)),
          SizedBox(width: widget.tokens.spaceXs / 2),
          _Dot(color: widget.tokens.primary, opacity: opacity(phase3)),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double opacity;

  const _Dot({required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
