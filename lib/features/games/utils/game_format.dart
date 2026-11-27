import 'package:intl/intl.dart';

final NumberFormat _decimalPattern = NumberFormat.decimalPattern('de');

/// Formatiert eine Ganzzahl mit deutschen Tausendertrennzeichen.
String formatInt(num value) => _decimalPattern.format(value);

/// Formatiert eine Dezimalzahl mit deutschem Komma.
String formatDecimal(num value, {int digits = 1}) {
  return value.toStringAsFixed(digits).replaceAll('.', ',');
}

/// Formatiert einen Anteil (0…1) als Prozentwert.
String formatPercent(double fraction, {int digits = 0}) {
  if (!fraction.isFinite) return '–';
  return '${formatDecimal(fraction * 100, digits: digits)} %';
}

/// Formatiert Sekunden als `mm:ss`.
String formatMatchDuration(int seconds) {
  if (seconds <= 0) return '–';
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

/// Formatiert Sekunden als volle Minuten, z. B. „3118 s“ → „51 Min.“.
String formatPlayedMinutes(int seconds) {
  if (seconds <= 0) return '–';
  return '${seconds ~/ 60} Min.';
}

/// Formatiert Minecraft-Ticks (20 Ticks = 1 s) als Dauer.
String formatTicksAsDuration(int ticks) {
  final seconds = ticks ~/ 20;
  if (seconds <= 0) return '0 Min.';
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0) return '$hours Std. $minutes Min.';
  if (minutes > 0) return '$minutes Min.';
  return '$seconds s';
}

/// Formatiert Zentimeter als Zentimeter, Meter oder Kilometer.
String formatCentimeters(int centimeters) {
  if (centimeters <= 0) return '0 m';
  if (centimeters < 100) return '$centimeters cm';
  final meters = centimeters / 100;
  if (meters < 1000) return '${formatDecimal(meters, digits: 1)} m';
  return '${formatDecimal(meters / 1000, digits: 1)} km';
}

const Set<String> _minecraftTimeStats = <String>{
  'minecraft:play_time',
  'minecraft:total_world_time',
  'minecraft:sneak_time',
};

/// Formatiert einen Minecraft-Zähler passend zu seiner Einheit.
String formatMinecraftStatValue(String category, String stat, int value) {
  if (stat.endsWith('_one_cm')) return formatCentimeters(value);
  if (_minecraftTimeStats.contains(stat) ||
      stat.startsWith('minecraft:time_since_')) {
    return formatTicksAsDuration(value);
  }
  return formatInt(value);
}

const Map<String, String> _minecraftStatLabels = <String, String>{
  'minecraft:play_time': 'Spielzeit',
  'minecraft:total_world_time': 'Gesamtzeit',
  'minecraft:deaths': 'Tode',
  'minecraft:mob_kills': 'Mobs getötet',
  'minecraft:player_kills': 'Spieler getötet',
  'minecraft:jump': 'Sprünge',
  'minecraft:walk_one_cm': 'Gelaufen',
  'minecraft:sprint_one_cm': 'Gesprintet',
  'minecraft:fly_one_cm': 'Geflogen',
  'minecraft:swim_one_cm': 'Geschwommen',
  'minecraft:fall_one_cm': 'Gefallen',
  'minecraft:damage_dealt': 'Schaden ausgeteilt',
  'minecraft:damage_taken': 'Schaden erhalten',
  'minecraft:leave_game': 'Spiel verlassen',
  'minecraft:open_chest': 'Truhen geöffnet',
  'minecraft:open_shulker_box': 'Shulker-Boxen geöffnet',
};

const Map<String, String> _minecraftCategoryLabels = <String, String>{
  'minecraft:custom': 'Allgemein',
  'minecraft:mined': 'Abgebaute Blöcke',
  'minecraft:crafted': 'Hergestellt',
  'minecraft:used': 'Benutzt',
  'minecraft:broken': 'Zerbrochen',
  'minecraft:picked_up': 'Aufgesammelt',
  'minecraft:dropped': 'Fallengelassen',
  'minecraft:killed': 'Getötet',
  'minecraft:killed_by': 'Getötet von',
};

/// Deutscher Anzeigename einer Minecraft-Statistik, mit Fallback für
/// Vanilla-/Mod-Statistiken ohne festen Eintrag.
String minecraftStatLabel(String stat) =>
    _minecraftStatLabels[stat] ?? _humanizeMinecraftKey(stat);

/// Deutscher Anzeigename einer Minecraft-Kategorie.
String minecraftCategoryLabel(String category) =>
    _minecraftCategoryLabels[category] ?? _humanizeMinecraftKey(category);

String _humanizeMinecraftKey(String key) {
  final withoutNamespace = key.contains(':') ? key.split(':').last : key;
  final words = withoutNamespace.replaceAll('_', ' ').trim();
  if (words.isEmpty) return key;
  return words[0].toUpperCase() + words.substring(1);
}
