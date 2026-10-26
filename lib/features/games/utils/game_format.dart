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
