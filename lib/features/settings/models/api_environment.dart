import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API-Instanz, die die App anspricht.
///
/// Relevant ist die Auswahl nur in Android-Debug-Builds; Release-Builds
/// bekommen ihre Instanz beim Build mitgegeben (siehe `deploy.py`).
enum ApiEnvironment {
  /// Produktiv-Instanz (`API_BASE_URL`).
  release,

  /// Preview-Instanz (`PREVIEW_API_BASE_URL`).
  preview,
}

extension ApiEnvironmentX on ApiEnvironment {
  String get label => switch (this) {
    ApiEnvironment.release => 'RELEASE',
    ApiEnvironment.preview => 'PREVIEW',
  };

  String get description => switch (this) {
    ApiEnvironment.release => 'Produktiv-Server',
    ApiEnvironment.preview => 'Preview-Server für experimentelle Funktionen',
  };
}

/// Ob die API-Auswahl im Einstellungs-Screen angezeigt werden soll.
///
/// Nur im Debug-Build auf Android: Release-Nutzer haben nichts umzuschalten,
/// und andere Plattformen bekommen ihre Instanz über den Build.
bool get apiEnvironmentSwitchEnabled =>
    kDebugMode && !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Vom Build gesetzte API-Basis-URL (`--dart-define=API_BASE_URL=…`).
///
/// Der Preview-Deploy nutzt dies, um die Preview-Instanz in Release-Builds
/// zu backen, ohne die gebündelte `.env` zu verändern.
const String _buildTimeApiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// Ermittelt die effektive API-Basis-URL.
///
/// Priorität: Build-Zeit-Override → Debug-Auswahl (nur bei
/// [allowSelection]) → [releaseUrl].
String resolveApiBaseUrl({
  required ApiEnvironment selected,
  required String releaseUrl,
  required String previewUrl,
  required bool allowSelection,
}) {
  if (_buildTimeApiBaseUrl.isNotEmpty) return _buildTimeApiBaseUrl;
  if (allowSelection) {
    return selected == ApiEnvironment.preview ? previewUrl : releaseUrl;
  }
  return releaseUrl;
}

/// Lokale Persistenz der gewählten API-Instanz.
class ApiEnvironmentPreference {
  const ApiEnvironmentPreference._();

  static const _key = 'api_environment';

  static Future<ApiEnvironment> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    return ApiEnvironment.values.asNameMap()[name] ?? ApiEnvironment.release;
  }

  static Future<void> save(ApiEnvironment value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.name);
  }
}
