import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../weather/models/weather_models.dart';
import '../../weather/services/user_weather_location_service.dart';
import '../../weather/services/weather_service.dart';
import '../dashboard_widget.dart';
import '../dashboard_widget_spec.dart';

/// Anzeige-Datensatz des Wetters im Dashboard-Widget.
class WeatherRow implements DashboardRow {
  final String locationName;
  final double? temperatureC;
  final String? condition;
  final int? weatherCode;

  const WeatherRow({
    required this.locationName,
    this.temperatureC,
    this.condition,
    this.weatherCode,
  });

  factory WeatherRow.fromResponse({
    required String locationName,
    required WeatherResponse response,
  }) {
    final current = response.data.current;
    return WeatherRow(
      locationName: locationName,
      temperatureC: current?.temperatureC,
      condition: current?.condition,
      weatherCode: current?.weatherCode,
    );
  }

  factory WeatherRow.fromJson(Map<String, dynamic> json) {
    return WeatherRow(
      locationName: json['locationName'] as String,
      temperatureC: (json['temperatureC'] as num?)?.toDouble(),
      condition: json['condition'] as String?,
      weatherCode: json['weatherCode'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'locationName': locationName,
    'temperatureC': temperatureC,
    'condition': condition,
    'weatherCode': weatherCode,
  };
}

/// Widget „Wetter" – zeigt das aktuelle Wetter für einen gewählten Ort.
class WeatherWidgetSpec extends DashboardWidgetSpec {
  WeatherWidgetSpec(this._weatherLocations, this._weather);

  final UserWeatherLocationService _weatherLocations;
  final WeatherService _weather;

  @override
  DashboardWidgetType get type => DashboardWidgetType.weather;

  @override
  String get listRoute => '/wetter';

  @override
  Future<List<DashboardRow>> fetch(
    int count, {
    DashboardWidgetConfig? config,
  }) async {
    final locationId = config?.selectedLocationId;
    if (locationId == null || locationId.isEmpty) return const [];

    try {
      final locations = await _weatherLocations.list();
      final location = locations.firstWhere(
        (l) => l.id == locationId,
        orElse: () => throw Exception('Location not found'),
      );
      final response = await _weather.getWeather(
        citySlug: location.slug,
        lat: location.lat,
        lon: location.lon,
      );
      return [
        WeatherRow.fromResponse(locationName: location.name, response: response),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  DashboardRow rowFromJson(Map<String, dynamic> json) =>
      WeatherRow.fromJson(json);

  @override
  Widget rowBuilder(
    BuildContext context,
    DashboardRow row,
    VoidCallback? onTap,
  ) {
    final weather = row as WeatherRow;
    final tokens = DesignTheme.of(context);

    final parts = <String>[];
    if (weather.temperatureC != null) {
      parts.add('${weather.temperatureC!.toStringAsFixed(1)}\u00B0C');
    }
    if (weather.condition != null && weather.condition!.isNotEmpty) {
      parts.add(weather.condition!);
    } else if (weather.weatherCode != null) {
      parts.add('WMO ${weather.weatherCode}');
    }
    final detailText = parts.isNotEmpty ? parts.join(' \u2022 ') : 'Wetter';

    return PressScale(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.surfaceVariant,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
            ),
            child: Icon(
              Icons.wb_sunny_rounded,
              size: 18,
              color: tokens.primary,
            ),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  weather.locationName,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: tokens.spaceXs),
                DesignText(
                  detailText,
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onRowTap(BuildContext context, DashboardRow row) {
    context.go(listRoute);
  }
}
