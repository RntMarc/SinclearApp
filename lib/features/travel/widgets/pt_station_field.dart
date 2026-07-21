import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../models/pt_models.dart';

class PtStationField extends StatefulWidget {
  const PtStationField({
    required this.label,
    required this.onSelected,
    this.controller,
    this.focusNode,
    super.key,
  });

  final String label;
  final ValueChanged<PtStation> onSelected;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  @override
  State<PtStationField> createState() => _PtStationFieldState();
}

class _PtStationFieldState extends State<PtStationField> {
  late final TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  Timer? _debounce;
  List<PtStation> _suggestions = [];
  bool _loading = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _debounce?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    final text = _controller.text.trim();
    if (text.length < 2) {
      _removeOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(text));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final service = AppScope.of(context).publicTransport;
      final results = await service.searchStations(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
      if (results.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _loading = false;
      });
      _removeOverlay();
    }
  }

  void _select(PtStation station) {
    _controller.text = station.name;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: station.name.length),
    );
    _removeOverlay();
    widget.onSelected(station);
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(0, 8),
          showWhenUnlinked: false,
          child: _buildDropdown(context),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildDropdown(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(color: tokens.border),
          boxShadow: tokens.surfaceShadow,
        ),
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: _suggestions.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final station = _suggestions[index];
            return InkWell(
              onTap: () => _select(station),
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceMd),
                child: DesignText(
                  station.name,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        decoration: InputDecoration(
          labelText: widget.label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
          suffixIcon: _loading
              ? Padding(
                  padding: EdgeInsets.all(tokens.spaceSm),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: tokens.textLow,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
