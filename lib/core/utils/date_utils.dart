import 'package:flutter/material.dart' show TimeOfDay;
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

/// API-Zeitformat: UTC, kein T, kein Z, keine Millisekunden.
const _apiDateFormat = 'yyyy-MM-dd HH:mm:ss';
final _apiFormatter = DateFormat(_apiDateFormat);

final _apiDateOnlyFormatter = DateFormat('yyyy-MM-dd');

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

/// Formatiert ein Datum als zivilen API-Datumsstring `YYYY-MM-DD`.
///
/// Verwendet die lokalen Datumsfelder (kein [DateTime.toUtc]), da es sich um
/// ein Kalenderdatum ohne Uhrzeit/Zeitzone handelt.
String toApiDateOnly(DateTime date) => _apiDateOnlyFormatter.format(date);

/// Parst einen zivilen API-Datumsstring `YYYY-MM-DD` als lokales Datum.
///
/// Anders als [parseApiDate] wird ein Datum ohne Uhrzeit **nicht** als
/// UTC-Mitternacht interpretiert und verschoben, sondern als ziviler Tag
/// beibehalten – sonst landet ein ganztägiger Eintrag westlich von UTC am
/// Vortag.
DateTime parseApiDateOnly(String value) {
  final trimmed = value.trim();
  if (trimmed.length == 10) return DateTime.parse(trimmed);
  return DateTime.parse('${trimmed.substring(0, 10)}T00:00:00');
}

/// Liefert die IANA-Zeitzone; unbekannte oder leere Namen fallen auf UTC
/// zurueck. Setzt die in `TimeZoneService.init()` geladene Zeitzonen-Datenbank
/// voraus.
tz.Location resolveTimeZone(String? name) {
  if (name == null || name.trim().isEmpty) return tz.UTC;
  try {
    return tz.getLocation(name.trim());
  } catch (_) {
    return tz.UTC;
  }
}

/// Parst einen RFC-3339-Zeitpunkt (mit Offset oder `Z`) als UTC-Instant.
///
/// Erkennt zur Uebergangszeit auch das alte API-Format `YYYY-MM-DD HH:MM:SS`
/// (dann als UTC interpretiert).
DateTime parseApiInstant(String value) {
  final trimmed = value.trim();
  try {
    return DateTime.parse(trimmed).toUtc();
  } on FormatException {
    return DateTime.parse('${trimmed.replaceFirst(' ', 'T')}Z').toUtc();
  }
}

/// Formatiert einen Instant als RFC 3339 mit Offset der Zielzeitzone.
String toApiInstant(DateTime instant, String timezone) {
  final zoned = tz.TZDateTime.from(instant, resolveTimeZone(timezone));
  return _formatRfc3339(zoned);
}

/// Wandelt eine Wandzeit (Datum + Uhrzeit) in der Zielzeitzone in einen
/// UTC-Instant um. Sommer-/Winterzeit wird korrekt beruecksichtigt.
DateTime wallTimeToInstant(DateTime wallTime, String? timezone) {
  final location = resolveTimeZone(timezone);
  return tz.TZDateTime(
    location,
    wallTime.year,
    wallTime.month,
    wallTime.day,
    wallTime.hour,
    wallTime.minute,
  ).toUtc();
}

/// Liefert die Wandzeit eines Instants in der Zielzeitzone (ohne weiteren
/// Zeitzonenbezug, daher direkt formatierbar).
DateTime instantToWallTime(DateTime instant, String timezone) {
  final zoned = tz.TZDateTime.from(instant, resolveTimeZone(timezone));
  return DateTime(
    zoned.year,
    zoned.month,
    zoned.day,
    zoned.hour,
    zoned.minute,
  );
}

/// Formatiert einen Instant als `HH:mm` in der Zielzeitzone.
String formatTimeInZone(DateTime instant, String timezone) =>
    DateFormat('HH:mm').format(instantToWallTime(instant, timezone));

/// Formatiert einen Instant als `dd.MM.yyyy` in der Zielzeitzone.
String formatDateInZone(DateTime instant, String timezone) =>
    DateFormat('dd.MM.yyyy').format(instantToWallTime(instant, timezone));

/// Formatiert einen Instant als `dd.MM.yyyy HH:mm` in der Zielzeitzone.
String formatDateTimeInZone(DateTime instant, String timezone) =>
    DateFormat('dd.MM.yyyy HH:mm').format(
      instantToWallTime(instant, timezone),
    );

/// Formatiert einen Instant-Bereich in der Zielzeitzone:
/// eintägig `dd.MM.yyyy HH:mm – HH:mm`, sonst mit beiden Daten.
String formatInstantRangeInZone(
  DateTime start,
  DateTime end,
  String timezone,
) {
  final s = instantToWallTime(start, timezone);
  final e = instantToWallTime(end, timezone);
  if (s.year == e.year && s.month == e.month && s.day == e.day) {
    return '${DateFormat('dd.MM.yyyy HH:mm').format(s)} – '
        '${DateFormat('HH:mm').format(e)}';
  }
  return '${DateFormat('dd.MM.yyyy HH:mm').format(s)} – '
      '${DateFormat('dd.MM.yyyy HH:mm').format(e)}';
}

/// Formatiert einen Instant als ISO-artige Wandzeit fuer
/// `showDatePicker`/`showTimePicker`.
String formatRfc3339(tz.TZDateTime zoned) => _formatRfc3339(zoned);

String _formatRfc3339(tz.TZDateTime zoned) {
  final date = DateFormat('yyyy-MM-dd').format(zoned);
  final time = DateFormat('HH:mm:ss').format(zoned);
  final offset = zoned.timeZoneOffset;
  if (offset == Duration.zero) return '${date}T${time}Z';
  final sign = offset.isNegative ? '-' : '+';
  final absolute = offset.abs();
  final hours = absolute.inHours.toString().padLeft(2, '0');
  final minutes = (absolute.inMinutes % 60).toString().padLeft(2, '0');
  return '${date}T$time$sign$hours:$minutes';
}

/// Parst eine API-Uhrzeit `HH:MM:SS` (oder `HH:MM`) als [TimeOfDay].
TimeOfDay? parseApiTime(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parts = value.trim().split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

/// Formatiert eine [TimeOfDay] als API-Uhrzeit `HH:MM:SS`.
String toApiTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}:00';

/// Formatiert eine [TimeOfDay] als `HH:mm` für die Anzeige.
String formatTimeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

/// Kombiniert ein ziviles Datum mit einer optionalen Uhrzeit zu einem
/// lokalen Zeitpunkt.
///
/// Ohne Uhrzeit wird der Tagesbeginn (bzw. mit [endOfDay] 23:59) verwendet –
/// passend für ganztägige Einträge.
DateTime combineDateAndTime(DateTime date, TimeOfDay? time, {bool endOfDay = false}) {
  if (time != null) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
  return DateTime(date.year, date.month, date.day, endOfDay ? 23 : 0, endOfDay ? 59 : 0);
}

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

/// Datumsbereich ohne Uhrzeit für ganztägige Einträge: `dd.MM.yyyy` bei
/// eintägigen, sonst `dd.MM.yyyy – dd.MM.yyyy`.
String formatDayRange(DateTime start, DateTime end) {
  final s = start.toLocal();
  final e = end.toLocal();
  if (s.year == e.year && s.month == e.month && s.day == e.day) {
    return DateFormat('dd.MM.yyyy').format(s);
  }
  return '${DateFormat('dd.MM.yyyy').format(s)} – ${DateFormat('dd.MM.yyyy').format(e)}';
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
