class WeatherCurrent {
  final double? temperatureC;
  final double? humidity;
  final double? apparentTemperature;
  final double? precipitation;
  final int? weatherCode;
  final String? condition;
  final int? cloudCover;
  final double? windSpeed;
  final double? windDirection;
  final double? windGusts;
  final DateTime? observedAt;

  const WeatherCurrent({
    this.temperatureC,
    this.humidity,
    this.apparentTemperature,
    this.precipitation,
    this.weatherCode,
    this.condition,
    this.cloudCover,
    this.windSpeed,
    this.windDirection,
    this.windGusts,
    this.observedAt,
  });

  factory WeatherCurrent.fromJson(Map<String, dynamic> json) {
    return WeatherCurrent(
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      apparentTemperature:
          (json['apparent_temperature'] as num?)?.toDouble(),
      precipitation: (json['precipitation'] as num?)?.toDouble(),
      weatherCode: json['weather_code'] as int?,
      condition: json['condition'] as String?,
      cloudCover: json['cloud_cover'] as int?,
      windSpeed: (json['wind_speed'] as num?)?.toDouble(),
      windDirection: (json['wind_direction'] as num?)?.toDouble(),
      windGusts: (json['wind_gusts'] as num?)?.toDouble(),
      observedAt: json['observed_at'] != null
          ? DateTime.tryParse(json['observed_at'] as String)
          : null,
    );
  }
}

class WeatherHourly {
  final DateTime? time;
  final double? temperatureC;
  final int? precipitationProbability;
  final int? weatherCode;
  final double? windSpeed;

  const WeatherHourly({
    this.time,
    this.temperatureC,
    this.precipitationProbability,
    this.weatherCode,
    this.windSpeed,
  });

  factory WeatherHourly.fromJson(Map<String, dynamic> json) {
    return WeatherHourly(
      time: json['time'] != null
          ? DateTime.tryParse(json['time'] as String)
          : null,
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      precipitationProbability: json['precipitation_probability'] as int?,
      weatherCode: json['weather_code'] as int?,
      windSpeed: (json['wind_speed'] as num?)?.toDouble(),
    );
  }
}

class WeatherDaily {
  final String? date;
  final int? weatherCode;
  final double? temperatureMaxC;
  final double? temperatureMinC;
  final double? precipitationSum;
  final int? precipitationProbabilityMax;
  final DateTime? sunrise;
  final DateTime? sunset;
  final double? uvIndexMax;
  final double? windSpeedMax;

  const WeatherDaily({
    this.date,
    this.weatherCode,
    this.temperatureMaxC,
    this.temperatureMinC,
    this.precipitationSum,
    this.precipitationProbabilityMax,
    this.sunrise,
    this.sunset,
    this.uvIndexMax,
    this.windSpeedMax,
  });

  factory WeatherDaily.fromJson(Map<String, dynamic> json) {
    return WeatherDaily(
      date: json['date'] as String?,
      weatherCode: json['weather_code'] as int?,
      temperatureMaxC: (json['temperature_max_c'] as num?)?.toDouble(),
      temperatureMinC: (json['temperature_min_c'] as num?)?.toDouble(),
      precipitationSum: (json['precipitation_sum'] as num?)?.toDouble(),
      precipitationProbabilityMax:
          json['precipitation_probability_max'] as int?,
      sunrise: json['sunrise'] != null
          ? DateTime.tryParse(json['sunrise'] as String)
          : null,
      sunset: json['sunset'] != null
          ? DateTime.tryParse(json['sunset'] as String)
          : null,
      uvIndexMax: (json['uv_index_max'] as num?)?.toDouble(),
      windSpeedMax: (json['wind_speed_max'] as num?)?.toDouble(),
    );
  }
}

class WeatherData {
  final WeatherCurrent? current;
  final List<WeatherHourly> hourly;
  final List<WeatherDaily> daily;

  const WeatherData({
    this.current,
    this.hourly = const [],
    this.daily = const [],
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      current: json['current'] != null
          ? WeatherCurrent.fromJson(json['current'] as Map<String, dynamic>)
          : null,
      hourly: (json['hourly'] as List?)
              ?.map((e) =>
                  WeatherHourly.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      daily: (json['daily'] as List?)
              ?.map((e) =>
                  WeatherDaily.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WeatherMeta {
  final List<String> missingSections;
  final List<String> availableSections;
  final String? source;

  const WeatherMeta({
    this.missingSections = const [],
    this.availableSections = const [],
    this.source,
  });

  factory WeatherMeta.fromJson(Map<String, dynamic> json) {
    return WeatherMeta(
      missingSections: (json['missing_sections'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      availableSections: (json['available_sections'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      source: json['source'] as String?,
    );
  }
}

class WeatherResponse {
  final WeatherData data;
  final WeatherMeta meta;

  const WeatherResponse({required this.data, required this.meta});

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    return WeatherResponse(
      data: WeatherData.fromJson(json['data'] as Map<String, dynamic>),
      meta: WeatherMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class LocationSearchResult {
  final String name;
  final String? slug;
  final double? lat;
  final double? lon;
  final bool recommended;
  final String source;
  final String? state;
  final int? population;

  const LocationSearchResult({
    required this.name,
    this.slug,
    this.lat,
    this.lon,
    this.recommended = false,
    this.source = 'nominatim',
    this.state,
    this.population,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    return LocationSearchResult(
      name: json['name'] as String,
      slug: json['slug'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      recommended: json['recommended'] as bool? ?? false,
      source: json['source'] as String? ?? 'nominatim',
      state: json['state'] as String?,
      population: json['population'] as int?,
    );
  }

  String get displayName {
    if (state != null && state!.isNotEmpty) return '$name, $state';
    return name;
  }
}

class SavedLocation {
  final String name;
  final String? slug;
  final double lat;
  final double lon;
  final String source;

  const SavedLocation({
    required this.name,
    this.slug,
    required this.lat,
    required this.lon,
    this.source = 'nominatim',
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      name: json['name'] as String,
      slug: json['slug'] as String?,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      source: json['source'] as String? ?? 'nominatim',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'lat': lat,
        'lon': lon,
        'source': source,
      };
}
