import 'package:flutter/material.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
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

    return DesignSurface(
      child: Stack(
        children: [
          _locations.isEmpty
              ? _buildEmpty(tokens)
              : _buildList(tokens),
          if (canAdd)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                heroTag: 'weather_add',
                onPressed: _addLocation,
                tooltip: 'Ort hinzufügen',
                child: const Icon(Icons.add_location_alt_rounded),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(DesignTokens tokens) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_sunny_outlined, size: 64, color: tokens.textLow),
          SizedBox(height: tokens.spaceLg),
          DesignText(
            'Keine Orte gespeichert',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Tippe auf + um einen Ort hinzuzufügen',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
      ),
    );
  }

  Widget _buildList(DesignTokens tokens) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceXxl + 80,
      ),
      itemCount: _locations.length,
      itemBuilder: (context, index) {
        final loc = _locations[index];
        return Dismissible(
          key: ValueKey('weather_${loc.slug ?? loc.lat}_${loc.lon}_$index'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _removeLocation(index),
          background: Container(
            alignment: Alignment.centerRight,
            margin: EdgeInsets.only(bottom: tokens.spaceSm),
            padding: EdgeInsets.only(right: tokens.spaceLg),
            decoration: BoxDecoration(
              color: tokens.danger,
              borderRadius: BorderRadius.circular(tokens.radiusLg),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: tokens.surface,
            ),
          ),
          child: WeatherSummaryCard(
            citySlug: loc.slug,
            lat: loc.lat,
            lon: loc.lon,
            locationName: loc.name,
          ),
        );
      },
    );
  }
}
