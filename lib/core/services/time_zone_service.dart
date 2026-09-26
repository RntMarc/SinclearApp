import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Verwaltet die effektive IANA-Zeitzone des Nutzers.
///
/// Reihenfolge: gespeicherte Praeferenz (`UserPreferences.timezone`) vor
/// Geraetezeitzone vor UTC. Die tz-Datenbank wird einmalig in [init] geladen
/// und muss vor jeder Nutzung der Zeitzonen-Helfer bereitstehen.
class TimeZoneService {
  static const String fallback = 'UTC';

  String _device = fallback;
  String _preference = '';
  bool _initialized = false;

  /// IANA-Zeitzone des Geraets (Fallback, wenn keine Praeferenz gesetzt ist).
  String get device => _device;

  /// Effektive Zeitzone fuer neue Eintraege und Anzeigen ohne Eintragszeitzone.
  String get effective => _preference.isNotEmpty ? _preference : _device;

  /// Laedt die Zeitzonen-Datenbank und liest die Geraetezeitzone.
  Future<void> init() async {
    tzdata.initializeTimeZones();
    _initialized = true;
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      _device = normalize(info.identifier);
    } catch (_) {
      _device = fallback;
    }
  }

  /// Uebernimmt die gespeicherte Nutzerpraeferenz; null/leer bedeutet
  /// Geraetezeitzone.
  void setPreference(String? timezone) {
    _preference = timezone == null || timezone.trim().isEmpty
        ? ''
        : normalize(timezone);
  }

  /// Liefert den kanonischen IANA-Namen oder [fallback].
  String normalize(String? name) {
    if (name == null || name.trim().isEmpty) return fallback;
    final candidate = name.trim();
    if (!_initialized) return candidate;
    try {
      return tz.getLocation(candidate).name;
    } catch (_) {
      return fallback;
    }
  }

  /// Alle auswaehlbaren IANA-Zeitzonen (sortiert).
  List<String> get availableZones {
    if (!_initialized) return const [fallback];
    final names = tz.timeZoneDatabase.locations.keys.toList()..sort();
    return names;
  }
}
