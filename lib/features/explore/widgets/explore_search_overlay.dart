import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';

import '../models/explore_models.dart';

class ExploreSearchOverlay extends StatefulWidget {
  const ExploreSearchOverlay({super.key});

  @override
  State<ExploreSearchOverlay> createState() => _ExploreSearchOverlayState();
}

class _ExploreSearchOverlayState extends State<ExploreSearchOverlay> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchMode = 'name';
  String? _selectedCategory;
  double _radius = 5000;
  bool _searching = false;

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() => _searching = true);

    try {
      final explore = AppScope.of(context).explore;
      final ExploreListResponse response;

      if (_searchMode == 'name') {
        response = await explore.search(q: query, category: _selectedCategory);
      } else {
        response = await explore.search(
          location: query,
          radius: _radius.round(),
          category: _selectedCategory,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, response);
    } catch (e, st) {
      developer.log('Search failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Suche fehlgeschlagen.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.pop(context),
            ),
            title: 'Suchen',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DesignTextField(
                    controller: _queryController,
                    hint: _searchMode == 'name'
                        ? 'Orte, Kategorien…'
                        : 'Stadt, Stadtteil…',
                    prefixIcon: Icons.search_rounded,
                  ),
                  SizedBox(height: tokens.spaceXl),
                  Row(
                    children: [
                      Expanded(
                        child: DesignButton(
                          variant: _searchMode == 'name'
                              ? DesignButtonVariant.filled
                              : DesignButtonVariant.outlined,
                          label: 'Name',
                          icon: Icons.search_rounded,
                          onPressed: () {
                            setState(() => _searchMode = 'name');
                            _focusNode.requestFocus();
                          },
                        ),
                      ),
                      SizedBox(width: tokens.spaceSm),
                      Expanded(
                        child: DesignButton(
                          variant: _searchMode == 'location'
                              ? DesignButtonVariant.filled
                              : DesignButtonVariant.outlined,
                          label: 'Ort/Region',
                          icon: Icons.location_on_rounded,
                          onPressed: () {
                            setState(() => _searchMode = 'location');
                            _focusNode.requestFocus();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spaceXl),
                  DesignText(
                    'Kategorie',
                    style: DesignTextStyle.subtitle,
                    color: tokens.textLow,
                  ),
                  SizedBox(height: tokens.spaceSm),
                  Wrap(
                    spacing: tokens.spaceSm,
                    children: [
                      DesignChip(
                        label: 'Alle',
                        selected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      DesignChip(
                        label: 'Gastronomie',
                        selected: _selectedCategory == 'gastronomy',
                        onTap: () =>
                            setState(() => _selectedCategory = 'gastronomy'),
                      ),
                      DesignChip(
                        label: 'Freizeit',
                        selected: _selectedCategory == 'leisure',
                        onTap: () =>
                            setState(() => _selectedCategory = 'leisure'),
                      ),
                    ],
                  ),
                  if (_searchMode == 'location') ...[
                    SizedBox(height: tokens.spaceXl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DesignText(
                          'Umkreis',
                          style: DesignTextStyle.subtitle,
                          color: tokens.textLow,
                        ),
                        DesignText(
                          '${(_radius / 1000).round()} km',
                          style: DesignTextStyle.title,
                          color: tokens.textHigh,
                        ),
                      ],
                    ),
                    Material(
                      type: MaterialType.transparency,
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: tokens.primary,
                          inactiveTrackColor: tokens.border,
                          thumbColor: tokens.primary,
                          overlayColor: tokens.primary.withValues(alpha: 0.12),
                          valueIndicatorColor: tokens.primary,
                          valueIndicatorTextStyle: TextStyle(
                            color: tokens.surface,
                            fontSize: 15,
                          ),
                        ),
                        child: Slider(
                          value: _radius,
                          min: 1000,
                          max: 50000,
                          divisions: 49,
                          label: '${(_radius / 1000).round()} km',
                          onChanged: (v) => setState(() => _radius = v),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DesignText(
                          '1 km',
                          style: DesignTextStyle.label,
                          color: tokens.textLow,
                        ),
                        DesignText(
                          '50 km',
                          style: DesignTextStyle.label,
                          color: tokens.textLow,
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: tokens.spaceXxl),
                  DesignButton(
                    variant: DesignButtonVariant.filled,
                    icon: Icons.search_rounded,
                    label: _searching ? 'Suche läuft…' : 'Suchen',
                    fullWidth: true,
                    loading: _searching,
                    onPressed: _searching ? null : _search,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
