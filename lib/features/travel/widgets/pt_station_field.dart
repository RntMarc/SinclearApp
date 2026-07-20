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
  Timer? _debounce;
  List<PtStation> _suggestions = [];
  bool _loading = false;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    final text = _controller.text.trim();
    if (text.length < 2) {
      setState(() {
        _suggestions = [];
        _showDropdown = false;
      });
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
        _showDropdown = results.isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _showDropdown = false;
        _loading = false;
      });
    }
  }

  void _select(PtStation station) {
    _controller.text = station.name;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: station.name.length),
    );
    setState(() => _showDropdown = false);
    widget.onSelected(station);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            focusNode: widget.focusNode,
            decoration: InputDecoration(
              labelText: widget.label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMd),
              ),
              suffixIcon:
                  _loading
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
          if (_showDropdown && _suggestions.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: tokens.spaceXs),
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
        ],
      ),
    );
  }
}
