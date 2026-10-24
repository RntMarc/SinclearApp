import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';
import '../primitives/design_icon_button.dart';

/// Eingabefeld am unteren Rand einer Chat-Konversation.
///
/// Mehrzeilige Texteingabe (max. 2000 Zeichen, serverseitiges Limit) mit
/// Senden-Button. Während [sending] wird ein Ladeindikator gezeigt und das
/// Senden gesperrt, bis der Server geantwortet hat.
///
/// **Edit-Modus:** Wird [editInitialText] gesetzt, wechselt der Composer
/// in den Bearbeitungsmodus — der Text wird vorausgefüllt, ein Label mit
/// Abbrechen-Button erscheint über dem Eingabefeld, und das Sende-Icon
/// wechselt zu einem Häkchen. Beim Verlassen des Modus (Speichern oder
/// Abbrechen) kehrt der vorherige Entwurf zurück, damit ein gespeicherter
/// Nachrichtentext nicht als neue Nachricht im Feld stehen bleibt.
class DesignChatComposer extends StatefulWidget {
  final String hintText;

  /// `true`, während die Nachricht auf den Server gesendet wird.
  final bool sending;

  /// Meldet den Text und liefert `true`, wenn das Senden erfolgreich war.
  /// Nur dann leert der Composer das Feld; bei `false` bleibt der Text zum
  /// erneuten Senden stehen.
  final Future<bool> Function(String) onSend;

  /// Wenn gesetzt, wird der Composer im Bearbeitungsmodus angezeigt mit
  /// diesem Text als Startwert. Der Parent muß [onCancelEdit] aufrufen,
  /// um den Modus zu verlassen.
  final String? editInitialText;

  /// Label über dem Eingabefeld im Edit-Modus (z. B. „Nachricht bearbeiten").
  final String? editLabel;

  /// Wird im Edit-Modus beim Tippen auf den Abbrechen-Button aufgerufen.
  final VoidCallback? onCancelEdit;

  /// Antwort-Modus: Name des Absenders der zitierten Nachricht.
  final String? replySenderName;

  /// Antwort-Modus: gekürzter Text der zitierten Nachricht.
  final String? replySnippet;

  /// Antwort-Modus: wird beim Abbrechen der Antwort aufgerufen.
  final VoidCallback? onCancelReply;

  /// Wird bei jeder Texteingabe aufgerufen (z. B. für Tippindikator).
  final VoidCallback? onTyping;

  const DesignChatComposer({
    this.hintText = 'Nachricht schreiben...',
    this.sending = false,
    required this.onSend,
    this.editInitialText,
    this.editLabel,
    this.onCancelEdit,
    this.replySenderName,
    this.replySnippet,
    this.onCancelReply,
    this.onTyping,
    super.key,
  });

  @override
  State<DesignChatComposer> createState() => _DesignChatComposerState();
}

class _DesignChatComposerState extends State<DesignChatComposer> {
  static const _maxLength = 2000;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// Text, der vor dem Start der Bearbeitung im Feld stand.
  String _draftBeforeEdit = '';

  /// Lokales Lock: gesetzt, bevor auf den Server gewartet wird, damit ein
  /// zweiter Tap/Enter im selben Frame keinen zweiten Request auslöst.
  bool _submitting = false;

  bool get _isEditing => widget.editInitialText != null;

  bool get _busy => _submitting || widget.sending;

  @override
  void initState() {
    super.initState();
    final initial = widget.editInitialText;
    if (initial != null) _fillWithEditText(initial);
  }

  @override
  void didUpdateWidget(covariant DesignChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasEditing = oldWidget.editInitialText != null;
    final isEditing = widget.editInitialText != null;
    if (!wasEditing && isEditing) {
      _draftBeforeEdit = _controller.text;
      _fillWithEditText(widget.editInitialText);
    } else if (wasEditing &&
        isEditing &&
        oldWidget.editInitialText != widget.editInitialText) {
      // Wechsel des Bearbeitungsziels: Entwurf bleibt gesichert.
      _fillWithEditText(widget.editInitialText);
    } else if (wasEditing && !isEditing) {
      // Speichern oder Abbrechen: der Text der bearbeiteten Nachricht darf
      // nicht als neue Nachricht im Feld zurückbleiben.
      _controller.text = _draftBeforeEdit;
      _draftBeforeEdit = '';
    }
  }

  void _fillWithEditText(String? text) {
    _controller.text = text ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    final wasEditing = _isEditing;
    setState(() => _submitting = true);
    try {
      final sent = await widget.onSend(text);
      if (!mounted || !sent) return;
      // Im Edit-Modus räumt der Moduswechsel das Feld auf. Beim normalen
      // Senden nur löschen, wenn währenddessen kein neuer Text getippt wurde.
      if (!wasEditing && _controller.text.trim() == text) _controller.clear();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isEditing)
          _ComposerBanner(
            icon: Icons.edit_rounded,
            label: widget.editLabel ?? 'Nachricht bearbeiten',
            onCancel: _busy ? null : widget.onCancelEdit,
          )
        else if (widget.replySnippet != null)
          _ComposerBanner(
            icon: Icons.reply_rounded,
            label:
                'Antwort an '
                '${widget.replySenderName?.isNotEmpty == true ? widget.replySenderName : 'Nachricht'}',
            snippet: widget.replySnippet,
            onCancel: _busy ? null : widget.onCancelReply,
          ),
        Container(
          decoration: BoxDecoration(
            color: tokens.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
          padding: EdgeInsets.all(tokens.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    maxLength: _maxLength,
                    style: tokens.bodyStyle(tokens.textHigh),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: tokens.bodyStyle(tokens.textLow),
                      border: InputBorder.none,
                      isCollapsed: true,
                      counterText: '',
                    ),
                    onChanged: (_) => widget.onTyping?.call(),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              if (_busy)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: tokens.primary,
                  ),
                )
              else
                DesignIconButton(
                  icon: _isEditing ? Icons.check_rounded : Icons.send_rounded,
                  tinted: true,
                  onPressed: _send,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kontext-Banner über dem Eingabefeld (Edit- oder Antwort-Modus).
class _ComposerBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? snippet;

  /// `null` deaktiviert den Abbrechen-Button (z. B. während gesendet wird).
  final VoidCallback? onCancel;

  const _ComposerBanner({
    required this.icon,
    required this.label,
    this.snippet,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final text = snippet;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd,
        vertical: tokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: tokens.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusLg),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: tokens.primary),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DesignText(
                  label,
                  style: DesignTextStyle.label,
                  color: tokens.primary,
                ),
                if (text != null && text.isNotEmpty)
                  DesignText(
                    text,
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Opacity(
            opacity: onCancel == null ? 0.4 : 1,
            child: DesignIconButton(
              icon: Icons.close_rounded,
              onPressed: onCancel,
            ),
          ),
        ],
      ),
    );
  }
}
