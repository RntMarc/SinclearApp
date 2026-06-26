import 'package:intl/intl.dart';

DateTime parseUtcToLocal(String iso) {
  return DateTime.parse(iso).toLocal();
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

String formatDateRange(DateTime start, DateTime end) {
  final s = start.toLocal();
  final e = end.toLocal();
  if (s.year == e.year && s.month == e.month && s.day == e.day) {
    return '${DateFormat('dd.MM.yyyy').format(s)} ${DateFormat('HH:mm').format(s)} – ${DateFormat('HH:mm').format(e)}';
  }
  return '${DateFormat('dd.MM.yyyy HH:mm').format(s)} – ${DateFormat('dd.MM.yyyy HH:mm').format(e)}';
}

String toApiDate(DateTime date) {
  return date.toUtc().toIso8601String();
}
