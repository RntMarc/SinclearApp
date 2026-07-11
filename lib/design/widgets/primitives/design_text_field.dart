import 'package:flutter/material.dart';
import '../../theme/design_theme.dart';

/// Custom text input that follows the active design tokens. Avoids Material
/// [TextField] styling so the look stays entirely within the catalog system.
class DesignTextField extends StatefulWidget {
  const DesignTextField({
    this.hint,
    this.controller,
    this.obscure = false,
    this.keyboardType,
    super.key,
  });

  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  State<DesignTextField> createState() => _DesignTextFieldState();
}

class _DesignTextFieldState extends State<DesignTextField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
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
        border: Border.all(color: borderColor.withValues(alpha: 0.8), width: 1.5),
        boxShadow: _focused ? tokens.glowShadow : null,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              style: tokens.bodyStyle(tokens.textHigh),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: tokens.bodyStyle(tokens.textLow),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
