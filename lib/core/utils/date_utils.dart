import 'package:intl/intl.dart';

/// API-Zeitformat: UTC, kein T, kein Z, keine Millisekunden.
const _apiDateFormat = 'yyyy-MM-dd HH:mm:ss';
final _apiFormatter = DateFormat(_apiDateFormat);

/// Formatiert ein DateTime als UTC-String im API-Format: `YYYY-MM-DD HH:MM:SS`.
String toApiDate(DateTime date) {
  return _apiFormatter.format(date.toUtc());
}

/// Parst einen API-String `YYYY-MM-DD HH:MM:SS` als UTC und konvertiert
/// zur lokalen Zeitzone.
///
/// Erkennt auch ältere ISO-8601-Formate (mit T, Z, Millisekunden) für
/// eine nahtlose Übergangsphase.
DateTime parseApiDate(String value) {
  final trimmed = value.trim();
  final hasTzIndicator =
      trimmed.endsWith('Z') ||
      trimmed.endsWith('z') ||
      trimmed.contains('+') ||
      (trimmed.length > 19 &&
          (trimmed[19] == '-' || trimmed[19] == '+') &&
          trimmed.codeUnitAt(10) == 84); // T separator

  if (hasTzIndicator) {
    return DateTime.parse(trimmed).toLocal();
  }
  return DateTime.parse('${trimmed}Z').toLocal();
}

/// Kompatibilitäts-alias – nutzt jetzt [parseApiDate].
DateTime parseUtcToLocal(String iso) => parseApiDate(iso);

String formatDate(DateTime date) {
  final local = date.toLocal();
  return DateFormat('dd.MM.yyyy').format(local);
}

String formatDateTime(DateTime date) {
  final local = date.toLocal();
  return DateFormat('dd.MM.yyyy HH:mm').format(local);
}

String formatTime(DateTime date) {
  final local = date.toLocal();
  return DateFormat('HH:mm').format(local);
}

String formatDateRange(DateTime start, DateTime end) {
  final s = start.toLocal();
  final e = end.toLocal();
  if (s.year == e.year && s.month == e.month && s.day == e.day) {
    return '${DateFormat('dd.MM.yyyy').format(s)} ${DateFormat('HH:mm').format(s)} – ${DateFormat('HH:mm').format(e)}';
  }
  return '${DateFormat('dd.MM.yyyy HH:mm').format(s)} – ${DateFormat('dd.MM.yyyy HH:mm').format(e)}';
}

String formatRelativeDate(String iso) {
  final date = parseApiDate(iso);
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.isNegative) return formatDate(date);
  if (diff.inMinutes < 1) return 'gerade eben';
  if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
  if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
  if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
  if (diff.inDays < 30) return 'vor ${diff.inDays ~/ 7} Wochen';
  return formatDate(date);
}
