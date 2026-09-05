import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/weather_models.dart';
import '../services/weather_service.dart';

/// Shows a location search sheet and returns the selected
/// [LocationSearchResult], or null if dismissed.
Future<LocationSearchResult?> showLocationSearchSheet(
  BuildContext context,
) {
  return showDesignSheet<LocationSearchResult>(
    context: context,
    child: const _LocationSearchBody(),
  );
}

class _LocationSearchBody extends StatefulWidget {
  const _LocationSearchBody();

  @override
  State<_LocationSearchBody> createState() => _LocationSearchBodyState();
}

class _LocationSearchBodyState extends State<_LocationSearchBody> {
  WeatherService get _service => AppScope.of(context).weather;
  final _controller = TextEditingController();
  Timer? _debounce;
  List<LocationSearchResult> _results = [];
  bool _loading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(value.trim());
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
    });
    try {
      final results = await _service.searchLocations(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        _hasSearched = true;
      });
    } catch (e, st) {
      debugPrint('Location search failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(
          'Ort suchen',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'Stadt eingeben…',
            hintStyle: TextStyle(color: tokens.textLow),
            prefixIcon: Icon(Icons.search_rounded, color: tokens.textLow),
            filled: true,
            fillColor: tokens.surfaceVariant.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMd,
              vertical: tokens.spaceSm,
            ),
          ),
          style: TextStyle(color: tokens.textHigh),
          textCapitalization: TextCapitalization.words,
        ),
        SizedBox(height: tokens.spaceMd),
        if (_loading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: CircularProgressIndicator(color: tokens.primary),
            ),
          )
        else if (_results.isEmpty && _hasSearched)
          Padding(
            padding: EdgeInsets.all(tokens.spaceLg),
            child: DesignText(
              'Keine Ergebnisse gefunden',
              style: DesignTextStyle.body,
              color: tokens.textLow,
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, _) => SizedBox(height: tokens.spaceXs),
              itemBuilder: (context, index) {
                final r = _results[index];
                return DesignCard(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.all(tokens.spaceMd),
                  onTap: () => Navigator.of(context).pop(r),
                  child: Row(
                    children: [
                      Icon(
                        r.recommended
                            ? Icons.location_on_rounded
                            : Icons.location_city_rounded,
                        color: r.recommended ? tokens.primary : tokens.textLow,
                        size: 20,
                      ),
                      SizedBox(width: tokens.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DesignText(
                              r.displayName,
                              style: DesignTextStyle.body,
                              color: tokens.textHigh,
                            ),
                            if (r.recommended)
                              DesignText(
                                'Empfohlen',
                                style: DesignTextStyle.label,
                                color: tokens.primary,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
