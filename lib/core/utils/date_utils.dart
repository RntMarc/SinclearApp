import 'package:intl/intl.dart';

/// API-Zeitformat: UTC, kein T, kein Z, keine Millisekunden.
const _apiDateFormat = 'yyyy-MM-dd HH:mm:ss';
final _apiFormatter = DateFormat(_apiDateFormat);

/// API-Zeitformat mit Millisekunden für exklusive Vergleiche.
const _apiDateFormatMs = 'yyyy-MM-dd HH:mm:ss.SSS';
final _apiFormatterMs = DateFormat(_apiDateFormatMs);

/// Formatiert ein DateTime als UTC-String im API-Format: `YYYY-MM-DD HH:MM:SS`.
///
/// Mit [withMilliseconds] wird die API-`since`-Grenze exklusiv: Die API
/// filtert `createdAt > since`, ohne Millisekunden fallen mehrere
/// Benachrichtigungen in derselben Sekunde erneut durch den Filter.
String toApiDate(DateTime date, {bool withMilliseconds = false}) {
  final formatter = withMilliseconds ? _apiFormatterMs : _apiFormatter;
  return formatter.format(date.toUtc());
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
  // Date-only strings (YYYY-MM-DD) need a time component for DateTime.parse.
  if (trimmed.length == 10) {
    return DateTime.parse('${trimmed}T00:00:00Z').toLocal();
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

/// Kalendertage von [from] nach [to] (0, wenn gleich; negativ in der
/// Vergangenheit). DST-sicher über UTC-Mitternacht.
int daysBetween(DateTime from, DateTime to) {
  return DateTime.utc(to.year, to.month, to.day)
      .difference(DateTime.utc(from.year, from.month, from.day))
      .inDays;
}

/// Der nächste Geburtstag ab [now]; fällt er auf heute, wird heute
/// zurückgegeben. Der 29. Februar wird in Nicht-Schaltjahren auf den
/// 1. März verschoben.
DateTime nextBirthday(DateTime birth, DateTime now) {
  final thisYear = _birthdayInYear(birth, now.year);
  return thisYear.isBefore(now) ? _birthdayInYear(birth, now.year + 1) : thisYear;
}

/// Alter in vollen Jahren am Tag [now], konsistent zu [nextBirthday].
int ageInYears(DateTime birth, DateTime now) {
  var age = now.year - birth.year;
  if (_birthdayInYear(birth, now.year).isAfter(now)) age--;
  return age;
}

/// Dauer von [start] bis [end] in grammatikalisch korrektem Deutsch:
/// "Seit 3 Jahren 6 Monaten und 12 Tagen", "Seit 2 Wochen und 1 Tag",
/// "Seit heute". Zu große (vordere) Einheiten werden weggelassen, Wochen
/// erscheinen nur unterhalb eines Monats.
String formatDuration(DateTime start, DateTime end) {
  if (end.isBefore(start)) return 'Seit heute';
  var years = end.year - start.year;
  var months = end.month - start.month;
  var days = end.day - start.day;
  if (days < 0) {
    months--;
    days += DateTime(end.year, end.month, 0).day;
  }
  if (months < 0) {
    years--;
    months += 12;
  }

  final parts = <String>[];
  if (years > 0) {
    parts.add(_unit(years, 'Jahr', 'Jahren'));
    if (months > 0) parts.add(_unit(months, 'Monat', 'Monaten'));
    if (days > 0) parts.add(_unit(days, 'Tag', 'Tagen'));
  } else if (months > 0) {
    parts.add(_unit(months, 'Monat', 'Monaten'));
    if (days > 0) parts.add(_unit(days, 'Tag', 'Tagen'));
  } else if (days >= 7) {
    final weeks = days ~/ 7;
    final rest = days % 7;
    parts.add(_unit(weeks, 'Woche', 'Wochen'));
    if (rest > 0) parts.add(_unit(rest, 'Tag', 'Tagen'));
  } else if (days > 0) {
    parts.add(_unit(days, 'Tag', 'Tagen'));
  } else {
    return 'Seit heute';
  }

  if (parts.length == 1) return 'Seit ${parts.single}';
  return 'Seit ${parts.sublist(0, parts.length - 1).join(' ')} und ${parts.last}';
}

/// Relatives Tagesdatum plus Uhrzeit für Story-Zeitstempel:
/// „Heute, 14:32", „Gestern, 09:15", „Vorgestern, 18:40",
/// „Vor 3 Tagen, 11:22"; ab 7 Tagen das absolute Datum.
String formatRelativeDayTime(String iso) {
  final date = parseApiDate(iso);
  final time = formatTime(date);
  final days = daysBetween(date, DateTime.now());
  if (days <= 0) return 'Heute, $time';
  if (days == 1) return 'Gestern, $time';
  if (days == 2) return 'Vorgestern, $time';
  if (days < 7) return 'Vor $days Tagen, $time';
  return '${formatDate(date)}, $time';
}

String _unit(int value, String singular, String plural) =>
    '$value ${value == 1 ? singular : plural}';

DateTime _birthdayInYear(DateTime birth, int year) {
  try {
    return DateTime(year, birth.month, birth.day);
  } on ArgumentError {
    return DateTime(year, 3, 1);
  }
}
