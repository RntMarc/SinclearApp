import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/weather_models.dart';
import '../services/weather_service.dart';

/// Shows a modal bottom sheet with full weather details for a location.
Future<void> showWeatherDetailSheet({
  required BuildContext context,
  required String locationName,
  String? citySlug,
  double? lat,
  double? lon,
}) {
  return showDesignSheet(
    context: context,
    child: _WeatherDetailBody(
      locationName: locationName,
      citySlug: citySlug,
      lat: lat,
      lon: lon,
    ),
  );
}

class _WeatherDetailBody extends StatefulWidget {
  final String locationName;
  final String? citySlug;
  final double? lat;
  final double? lon;

  const _WeatherDetailBody({
    required this.locationName,
    this.citySlug,
    this.lat,
    this.lon,
  });

  @override
  State<_WeatherDetailBody> createState() => _WeatherDetailBodyState();
}

class _WeatherDetailBodyState extends State<_WeatherDetailBody> {
  WeatherService get _service => AppScope.of(context).weather;

  WeatherResponse? _weather;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
      developer.log('Weather detail fetch failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
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
          widget.locationName.isNotEmpty
              ? 'Wetter \u2013 ${widget.locationName}'
              : 'Wetter',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        if (_loading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceXl),
              child: CircularProgressIndicator(color: tokens.primary),
            ),
          )
        else if (_error != null)
          DesignCard(
            margin: EdgeInsets.zero,
            child: DesignText(
              'Abruf von Wetter fehlgeschlagen',
              style: DesignTextStyle.body,
              color: tokens.textHigh,
            ),
          )
        else ...[
          if (_weather?.data.current != null) ...[
            _CurrentSection(current: _weather!.data.current!),
            SizedBox(height: tokens.spaceMd),
          ],
          if (_weather!.data.hourly.isNotEmpty) ...[
            _HourlySection(hourly: _weather!.data.hourly),
            SizedBox(height: tokens.spaceMd),
          ],
          if (_weather!.data.daily.isNotEmpty)
            _DailySection(daily: _weather!.data.daily),
        ],
      ],
    );
  }
}

class _CurrentSection extends StatelessWidget {
  final WeatherCurrent current;

  const _CurrentSection({required this.current});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final rows = <_InfoRow>[];

    if (current.temperatureC != null) {
      rows.add(_InfoRow(
        label: 'Temperatur',
        value: '${current.temperatureC!.toStringAsFixed(1)}\u00B0C',
      ));
    }
    if (current.apparentTemperature != null) {
      rows.add(_InfoRow(
        label: 'Gef\u00fchlt',
        value: '${current.apparentTemperature!.toStringAsFixed(1)}\u00B0C',
      ));
    }
    if (current.condition != null && current.condition!.isNotEmpty) {
      rows.add(_InfoRow(label: 'Bedingung', value: current.condition!));
    }
    if (current.humidity != null) {
      rows.add(_InfoRow(
        label: 'Luftfeuchtigkeit',
        value: '${current.humidity!.toStringAsFixed(0)}%',
      ));
    }
    if (current.windSpeed != null) {
      rows.add(_InfoRow(
        label: 'Wind',
        value: '${current.windSpeed!.toStringAsFixed(1)} km/h',
      ));
    }
    if (current.windGusts != null) {
      rows.add(_InfoRow(
        label: 'B\u00f6en',
        value: '${current.windGusts!.toStringAsFixed(1)} km/h',
      ));
    }
    if (current.windDirection != null) {
      rows.add(_InfoRow(
        label: 'Windrichtung',
        value: '${current.windDirection!.toStringAsFixed(0)}\u00B0',
      ));
    }
    if (current.cloudCover != null) {
      rows.add(_InfoRow(
        label: 'Bew\u00f6lkung',
        value: '${current.cloudCover}%',
      ));
    }
    if (current.precipitation != null) {
      rows.add(_InfoRow(
        label: 'Niederschlag',
        value: '${current.precipitation!.toStringAsFixed(1)} mm',
      ));
    }
    if (current.observedAt != null) {
      final local = current.observedAt!.toLocal();
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      rows.add(_InfoRow(label: 'Beobachtet', value: '$h:$m Uhr'));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return DesignCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(tokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            'Aktuell',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceSm),
          ...rows.map((r) => Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceXs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DesignText(
                      r.label,
                      style: DesignTextStyle.body,
                      color: tokens.textLow,
                    ),
                    DesignText(
                      r.value,
                      style: DesignTextStyle.body,
                      color: tokens.textHigh,
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _HourlySection extends StatelessWidget {
  final List<WeatherHourly> hourly;

  const _HourlySection({required this.hourly});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final preview = hourly.take(12).toList();

    return DesignCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(tokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            'St\u00fcndlich',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceSm),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (_, _) => SizedBox(width: tokens.spaceSm),
              itemBuilder: (context, index) {
                final h = preview[index];
                final time = h.time?.toLocal();
                final label = time != null
                    ? '${time.hour.toString().padLeft(2, '0')}:00'
                    : '--:--';
                final temp = h.temperatureC != null
                    ? '${h.temperatureC!.toStringAsFixed(0)}\u00B0'
                    : '--';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DesignText(
                      label,
                      style: DesignTextStyle.label,
                      color: tokens.textLow,
                    ),
                    SizedBox(height: tokens.spaceXs),
                    DesignText(
                      temp,
                      style: DesignTextStyle.body,
                      color: tokens.textHigh,
                    ),
                    if (h.precipitationProbability != null &&
                        h.precipitationProbability! > 0)
                      DesignText(
                        '${h.precipitationProbability}%',
                        style: DesignTextStyle.label,
                        color: tokens.primary,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySection extends StatelessWidget {
  final List<WeatherDaily> daily;

  const _DailySection({required this.daily});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.all(tokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignText(
            'T\u00e4glich',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceSm),
          ...daily.map((d) {
            final max = d.temperatureMaxC != null
                ? '${d.temperatureMaxC!.toStringAsFixed(0)}\u00B0'
                : '--';
            final min = d.temperatureMinC != null
                ? '${d.temperatureMinC!.toStringAsFixed(0)}\u00B0'
                : '--';
            final precip = d.precipitationProbabilityMax != null
                ? '${d.precipitationProbabilityMax}%'
                : '';
            return Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceXs),
              child: Row(
                children: [
                  Expanded(
                    child: DesignText(
                      d.date ?? '--',
                      style: DesignTextStyle.body,
                      color: tokens.textHigh,
                    ),
                  ),
                  DesignText(
                    '$max / $min',
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                  if (precip.isNotEmpty) ...[
                    SizedBox(width: tokens.spaceSm),
                    DesignText(
                      precip,
                      style: DesignTextStyle.label,
                      color: tokens.primary,
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});
}
