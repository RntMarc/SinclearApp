import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';
import '../primitives/design_icon_button.dart';

class CommentInput extends StatefulWidget {
  final String hintText;
  final bool autofocus;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onCancel;

  const CommentInput({
    super.key,
    this.hintText = 'Kommentar schreiben...',
    this.autofocus = false,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      widget.onSubmit(text);
      _controller.clear();
      _focusNode.unfocus();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                style: tokens.bodyStyle(tokens.textHigh),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: tokens.bodyStyle(tokens.textLow),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          if (widget.onCancel != null) ...[
            SizedBox(width: tokens.spaceSm),
            DesignIconButton(
              icon: Icons.close_rounded,
              onPressed: () {
                _controller.clear();
                widget.onCancel?.call();
              },
            ),
          ],
          SizedBox(width: tokens.spaceSm),
          _submitting
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
                  onPressed: _submit,
                ),
        ],
      ),
    );
  }
}
