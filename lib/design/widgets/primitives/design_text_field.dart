import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';

/// Custom text input that follows the active design tokens. Avoids Material
/// [TextField] styling so the look stays entirely within the catalog system.
class DesignTextField extends StatefulWidget {
  const DesignTextField({
    this.hint,
    this.controller,
    this.focusNode,
    this.obscure = false,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.maxLines = 1, // null = auto-expand
    this.maxLength,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.scrollPadding = const EdgeInsets.only(bottom: 140.0),
    super.key,
  });

  final String? hint;
  final TextEditingController? controller;

  /// Externer [FocusNode], z.B. um das Feld beim Öffnen eines Screens zu
  /// fokussieren. Ohne Angabe verwaltet das Widget einen eigenen internen.
  final FocusNode? focusNode;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final int? maxLines;
  final int? maxLength;
  final IconData? prefixIcon;

  /// An optional widget rendered after the text input (e.g. a
  /// [VisibilityBadge]). The suffix sits inside the field's border, aligned
  /// to the trailing edge, so it stays visually part of the same input row.
  final Widget? suffix;

  /// Called whenever the input value changes.
  final ValueChanged<String>? onChanged;

  /// Configures the padding for the edges surrounding a Scrollable when the
  /// text field scrolls into view. Defaults to [EdgeInsets.only(bottom: 140.0)].
  final EdgeInsets scrollPadding;

  @override
  State<DesignTextField> createState() => _DesignTextFieldState();
}

class _DesignTextFieldState extends State<DesignTextField> {
  FocusNode? _internalFocus;
  bool _focused = false;

  FocusNode get _focus {
    final external = widget.focusNode;
    if (external != null) return external;
    return _internalFocus ??= FocusNode();
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
    _focused = _focus.hasFocus;
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _internalFocus?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() => _focused = _focus.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final borderColor = _focused ? tokens.primary : tokens.border;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd,
        vertical: tokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: _focused ? tokens.glowShadow : null,
      ),
      child: Row(
        children: <Widget>[
          if (widget.prefixIcon != null) ...<Widget>[
            Icon(widget.prefixIcon, color: tokens.textLow, size: 20),
            SizedBox(width: tokens.spaceSm),
          ],
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                obscureText: widget.obscure,
                keyboardType: widget.keyboardType,
                textAlign: widget.textAlign,
                maxLines: widget.maxLines,
                maxLength: widget.maxLength,
                style: tokens.bodyStyle(tokens.textHigh),
                scrollPadding: widget.scrollPadding,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: tokens.bodyStyle(tokens.textLow),
                  border: InputBorder.none,
                  isCollapsed: true,
                  counterText: widget.maxLength != null ? '' : null,
                ),
              ),
            ),
          ),
          if (widget.suffix != null) ...<Widget>[
            SizedBox(width: tokens.spaceSm),
            widget.suffix!,
          ],
        ],
      ),
    );
  }
}
