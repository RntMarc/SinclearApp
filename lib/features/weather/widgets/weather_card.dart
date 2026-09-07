import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/weather_models.dart';
import '../services/weather_service.dart';
import 'weather_detail_sheet.dart';

/// Compact card showing current weather for a location.
///
/// Fetches weather via [WeatherService] using [citySlug] and/or
/// [lat]/[lon]. Tapping the card opens a detail sheet with full weather data.
/// On fetch failure the card stays visible with an error message.
class WeatherSummaryCard extends StatefulWidget {
  final String? citySlug;
  final double? lat;
  final double? lon;
  final String? locationName;
  final VoidCallback? onTap;

  const WeatherSummaryCard({
    super.key,
    this.citySlug,
    this.lat,
    this.lon,
    this.locationName,
    this.onTap,
  });

  @override
  State<WeatherSummaryCard> createState() => _WeatherSummaryCardState();
}

class _WeatherSummaryCardState extends State<WeatherSummaryCard> {
  WeatherService get _service => AppScope.of(context).weather;

  WeatherResponse? _weather;
  bool _loading = true;
  String? _error;
  bool _hasLoaded = false;

  bool get _hasLocation =>
      (widget.citySlug != null && widget.citySlug!.isNotEmpty) ||
      (widget.lat != null && widget.lon != null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded && _hasLocation) {
      _hasLoaded = true;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant WeatherSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.citySlug != widget.citySlug ||
        oldWidget.lat != widget.lat ||
        oldWidget.lon != widget.lon) {
      _hasLoaded = false;
      _weather = null;
      _error = null;
      _loading = true;
    }
  }

  Future<void> _load() async {
    if (!_hasLocation) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.getWeather(
        citySlug: widget.citySlug,
        lat: widget.lat,
        lon: widget.lon,
      );
      if (!mounted) return;
      setState(() {
        _weather = response;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Weather fetch failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openDetail() {
    showWeatherDetailSheet(
      context: context,
      locationName: widget.locationName ?? '',
      weatherService: _service,
      citySlug: widget.citySlug,
      lat: widget.lat,
      lon: widget.lon,
    );
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLocation) return const SizedBox.shrink();

    final tokens = DesignTheme.of(context);
    final current = _weather?.data.current;

    return DesignCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(tokens.spaceLg),
      onTap: _openDetail,
      child: Row(
        children: [
          _buildIcon(tokens, current),
          SizedBox(width: tokens.spaceLg),
          Expanded(child: _buildContent(tokens, current)),
          Icon(Icons.chevron_right_rounded, color: tokens.textLow, size: 20),
        ],
      ),
    );
  }

  Widget _buildIcon(DesignTokens tokens, WeatherCurrent? current) {
    if (_loading) {
      return _iconContainer(
        tokens,
        icon: Icons.wb_sunny_rounded,
        color: tokens.textLow,
      );
    }
    if (current == null || _error != null) {
      return _iconContainer(
        tokens,
        icon: Icons.cloud_off_rounded,
        color: tokens.textLow,
      );
    }
    return _iconContainer(
      tokens,
      icon: Icons.wb_sunny_rounded,
      color: tokens.primary,
    );
  }

  Widget _iconContainer(
    DesignTokens tokens, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildContent(DesignTokens tokens, WeatherCurrent? current) {
    final locationName = widget.locationName;
    final hasName = locationName != null && locationName.isNotEmpty;

    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasName)
            DesignText(
              locationName,
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
          DesignText(
            'Wetter laden…',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasName)
            DesignText(
              locationName,
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
          DesignText(
            'Abruf fehlgeschlagen',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
      );
    }

    if (current == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasName)
            DesignText(
              locationName,
              style: DesignTextStyle.subtitle,
              color: tokens.textHigh,
            ),
          DesignText(
            'Keine Daten verfügbar',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
      );
    }

    final parts = <String>[];
    if (current.temperatureC != null) {
      parts.add('${current.temperatureC!.toStringAsFixed(1)}\u00B0C');
    }
    if (current.condition != null && current.condition!.isNotEmpty) {
      parts.add(current.condition!);
    } else if (current.weatherCode != null) {
      parts.add('WMO ${current.weatherCode}');
    }

    final detailText = parts.isNotEmpty ? parts.join(' \u2022 ') : 'Wetter';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasName)
          DesignText(
            locationName,
            style: DesignTextStyle.subtitle,
            color: tokens.textHigh,
          ),
        DesignText(
          detailText,
          style: DesignTextStyle.label,
          color: tokens.textLow,
        ),
      ],
    );
  }
}
