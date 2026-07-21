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
    super.key,
  });

  final String label;
  final ValueChanged<PtStation> onSelected;
  final TextEditingController? controller;

  @override
  State<PtStationField> createState() => _PtStationFieldState();
}

class _PtStationFieldState extends State<PtStationField> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<PtStation> _suggestions = [];
  bool _loading = false;
  bool _showSuggestions = false;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (_isSelecting) return;
    _debounce?.cancel();
    final text = _controller.text.trim();
    if (text.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
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
        _showSuggestions = results.isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _loading = false;
      });
    }
  }

  void _select(PtStation station) {
    _isSelecting = true;
    _debounce?.cancel();
    _controller.text = station.name;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: station.name.length),
    );
    setState(() => _showSuggestions = false);
    _isSelecting = false;
    widget.onSelected(station);
  }

  void _closeSuggestions() {
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(color: tokens.border),
          boxShadow: tokens.surfaceShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
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
                    : _showSuggestions
                        ? IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: tokens.textLow, size: 20),
                            onPressed: _closeSuggestions,
                          )
                        : null,
              ),
            ),
            if (_showSuggestions && _suggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final station = _suggestions[index];
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
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
      ),
    );
  }
}
