import 'package:flutter/material.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_fab.dart';
import '../constants/weather_constants.dart';
import '../models/weather_models.dart';
import '../services/weather_preferences.dart';
import '../widgets/location_search_sheet.dart';
import '../widgets/weather_card.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherPreferences? _prefs;
  List<SavedLocation> _locations = [];
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _init();
    }
  }

  Future<void> _init() async {
    final prefs = await WeatherPreferences.create();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _locations = prefs.load();
    });
  }

  Future<void> _addLocation() async {
    if (_locations.length >= kMaxSavedWeatherLocations) return;
    final result = await showLocationSearchSheet(context);
    if (result == null || _prefs == null || !mounted) return;

    final slug = result.slug;
    final lat = result.lat;
    final lon = result.lon;

    if (slug == null && (lat == null || lon == null)) return;

    final location = SavedLocation(
      name: result.name,
      slug: slug,
      lat: lat ?? 0,
      lon: lon ?? 0,
      source: result.source,
    );

    await _prefs!.addLocation(location);
    if (!mounted) return;
    setState(() => _locations = _prefs!.load());
  }

  Future<void> _removeLocation(int index) async {
    if (_prefs == null || !mounted) return;
    await _prefs!.removeLocation(index);
    if (!mounted) return;
    setState(() => _locations = _prefs!.load());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final canAdd = _locations.length < kMaxSavedWeatherLocations;

    return Stack(
      children: [
        DesignSurface(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: RefreshIndicator(
            onRefresh: _init,
            child: _locations.isEmpty
                ? _buildEmpty(tokens)
                : _buildList(tokens, canAdd),
          ),
        ),
        if (canAdd)
          Positioned(
            right: tokens.spaceLg,
            bottom: tokens.spaceLg,
            child: DesignFab(
              icon: Icons.add_location_alt_rounded,
              onPressed: _addLocation,
              tooltip: 'Ort hinzufügen',
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty(DesignTokens tokens) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    size: 64,
                    color: tokens.textLow,
                  ),
                  SizedBox(height: tokens.spaceLg),
                  DesignText(
                    'Keine Orte gespeichert',
                    style: DesignTextStyle.body,
                    color: tokens.textLow,
                  ),
                  SizedBox(height: tokens.spaceSm),
                  DesignText(
                    'Tippe auf „Ort hinzufügen" unten',
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(DesignTokens tokens, bool canAdd) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceXxl,
      ),
      itemCount: _locations.length + (canAdd ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _locations.length) {
          return Padding(
            padding: EdgeInsets.only(top: tokens.spaceMd),
            child: DesignButton(
              label: 'Ort hinzufügen',
              icon: Icons.add_location_alt_rounded,
              variant: DesignButtonVariant.outlined,
              fullWidth: true,
              onPressed: _addLocation,
            ),
          );
        }
        final loc = _locations[index];
        return Padding(
          padding: EdgeInsets.only(bottom: tokens.spaceMd),
          child: Dismissible(
            key: ValueKey('weather_${loc.slug ?? loc.lat}_${loc.lon}_$index'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _removeLocation(index),
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: tokens.spaceLg),
              decoration: BoxDecoration(
                color: tokens.danger,
                borderRadius: BorderRadius.circular(tokens.radiusLg),
              ),
              child: Icon(Icons.delete_outline_rounded, color: tokens.surface),
            ),
            child: WeatherSummaryCard(
              citySlug: loc.slug,
              lat: loc.lat,
              lon: loc.lon,
              locationName: loc.name,
            ),
          ),
        );
      },
    );
  }
}
