import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          if (widget.onCancel != null)
            IconButton(
              onPressed: () {
                _controller.clear();
                widget.onCancel?.call();
              },
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          IconButton(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
          ),
        ],
      ),
    );
  }
}
