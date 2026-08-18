import 'package:flutter/material.dart';

import '../../theme/design_theme.dart';
import '../primitives/design_icon_button.dart';

/// Eingabefeld am unteren Rand einer Chat-Konversation.
///
/// Mehrzeilige Texteingabe (max. 2000 Zeichen, serverseitiges Limit) mit
/// Senden-Button. Während [sending] wird ein Ladeindikator gezeigt und das
/// Senden gesperrt, bis der Server geantwortet hat.
class DesignChatComposer extends StatefulWidget {
  final String hintText;

  /// `true`, während die Nachricht auf den Server gesendet wird.
  final bool sending;

  final ValueChanged<String> onSend;

  const DesignChatComposer({
    this.hintText = 'Nachricht schreiben...',
    this.sending = false,
    required this.onSend,
    super.key,
  });

  @override
  State<DesignChatComposer> createState() => _DesignChatComposerState();
}

class _DesignChatComposerState extends State<DesignChatComposer> {
  static const _maxLength = 2000;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

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
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Container(
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
                  icon: Icons.send_rounded,
                  tinted: true,
                  onPressed: _send,
                ),
        ],
      ),
    );
  }
}
