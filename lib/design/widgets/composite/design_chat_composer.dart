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
/// wechselt zu einem Häkchen.
class DesignChatComposer extends StatefulWidget {
  final String hintText;

  /// `true`, während die Nachricht auf den Server gesendet wird.
  final bool sending;

  final ValueChanged<String> onSend;

  /// Wenn gesetzt, wird der Composer im Bearbeitungsmodus angezeigt mit
  /// diesem Text als Startwert. Der Parent muß [onCancelEdit] aufrufen,
  /// um den Modus zu verlassen.
  final String? editInitialText;

  /// Label über dem Eingabefeld im Edit-Modus (z. B. „Nachricht bearbeiten").
  final String? editLabel;

  /// Wird im Edit-Modus beim Tippen auf den Abbrechen-Button aufgerufen.
  final VoidCallback? onCancelEdit;

  /// Wird bei jeder Texteingabe aufgerufen (z. B. für Tippindikator).
  final VoidCallback? onTyping;

  const DesignChatComposer({
    this.hintText = 'Nachricht schreiben...',
    this.sending = false,
    required this.onSend,
    this.editInitialText,
    this.editLabel,
    this.onCancelEdit,
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
  bool _previousIsEditing = false;

  bool get _isEditing => widget.editInitialText != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _controller.text = widget.editInitialText!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant DesignChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isEditing && !_previousIsEditing) {
      _controller.text = widget.editInitialText!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    }
    _previousIsEditing = _isEditing;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.sending) return;
    widget.onSend(text);
    if (!_isEditing) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isEditing)
          Container(
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
                Icon(Icons.edit_rounded, size: 16, color: tokens.primary),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: DesignText(
                    widget.editLabel ?? 'Nachricht bearbeiten',
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
                DesignIconButton(
                  icon: Icons.close_rounded,
                  onPressed: widget.onCancelEdit,
                ),
              ],
            ),
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
              widget.sending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: tokens.primary,
                      ),
                    )
                  : DesignIconButton(
                      icon: _isEditing
                          ? Icons.check_rounded
                          : Icons.send_rounded,
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
