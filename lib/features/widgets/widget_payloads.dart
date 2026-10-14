import '../../core/config/notification_config.dart';
import '../../core/utils/date_utils.dart';
import '../calendar/models/calendar_models.dart';
import '../notifications/models/notification_item.dart';
import '../travel/models/travel_models.dart';

/// Schemata der Widget-Payloads. Flutter baut hier die Anzeige-Daten und die
/// fertigen Deep-Link-Routen; die native Seite rendert sie nur noch.

/// Höchstzahl tappbarer Einträge im Aktivität-Widget.
const int activityMaxItems = 3;

/// Forum-Benachrichtigungstypen, die im Aktivität-Widget zählen.
const Set<String> forumNotificationTypes = <String>{
  'forum_reply',
  'forum_comment',
  'forum_post',
};

/// Eine ungelesene Forum-Aktivität (ein Post).
class ActivityItem {
  const ActivityItem({
    required this.route,
    required this.label,
  });

  /// Route des Posts, z. B. `/forum/{id}/beitrag/{postId}`.
  final String route;
  final String label;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'route': route,
    'label': label,
  };
}

/// Payload des Aktivität-Widgets (Zähler + Liste ungelesener Posts).
class ActivityPayload {
  const ActivityPayload({required this.total, required this.items});

  final int total;
  final List<ActivityItem> items;

  /// Baut den Payload aus der Liste ungelesener Benachrichtigungen.
  /// Gezählt werden alle Forum-Typen; als tappbare Einträge erscheinen die
  /// ersten [activityMaxItems] unterschiedlichen Posts.
  static ActivityPayload fromUnread(List<NotificationItem> unread) {
    final seenPosts = <String>{};
    final items = <ActivityItem>[];
    var total = 0;

    for (final item in unread) {
      if (!forumNotificationTypes.contains(item.type)) continue;
      total++;

      final forumId = item.identifierFor('parent_forum');
      final postId = item.identifierFor('parent_post');
      if (forumId == null || postId == null) continue;
      if (items.length >= activityMaxItems) continue;

      final key = '$forumId:$postId';
      if (!seenPosts.add(key)) continue;

      final label = (item.title != null && item.title!.isNotEmpty)
          ? item.title!
          : ((item.text != null && item.text!.isNotEmpty)
                ? item.text!
                : NotificationTypeLabel.title(item.type));
      items.add(ActivityItem(route: '/forum/$forumId/beitrag/$postId', label: label));
    }

    return ActivityPayload(total: total, items: items);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'total': total,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

/// Ein heutiger Termin im Widget.
class TodayItem {
  const TodayItem({
    required this.route,
    required this.title,
    this.time,
    this.allDay = false,
  });

  final String route;
  final String title;

  /// `HH:mm` bei getakteten Einträgen, `null` bei ganztägigen.
  final String? time;
  final bool allDay;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'route': route,
    'title': title,
    if (time != null) 'time': time,
    'allDay': allDay,
  };
}

/// Payload des Heute-Widgets (heutige Termine aus `/calendar/all`).
class TodayPayload {
  const TodayPayload({required this.items});

  final List<TodayItem> items;

  static TodayPayload fromEntries(List<CalendarEntry> entries) {
    final items = <TodayItem>[];
    for (final entry in entries) {
      final route = _todayRoute(entry);
      if (route == null) continue;
      items.add(
        TodayItem(
          route: route,
          title: entry.title ?? _typeFallback(entry.type),
          time: entry.allDay
              ? null
              : (entry.startAt == null
                    ? null
                    : formatTimeInZone(entry.startAt!, entry.timezone)),
          allDay: entry.allDay,
        ),
      );
    }
    return TodayPayload(items: items);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'items': items.map((e) => e.toJson()).toList(),
  };
}

/// Payload des Nächste-Reise-Widgets.
class TripPayload {
  const TripPayload({
    this.route,
    this.title,
    this.dateLabel,
    this.daysUntil,
  });

  /// `null`, wenn keine bevorstehende/laufende Reise existiert.
  final String? route;
  final String? title;
  final String? dateLabel;

  /// Kalendertage bis zum Start (0 = heute, negativ = läuft bereits).
  final int? daysUntil;

  /// Wählt die nächste (laufende oder bevorstehende) Reise aus.
  static TripPayload fromTrips(List<TravelTrip> trips, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    TravelTrip? next;
    for (final trip in trips) {
      final endDay = _localDay(trip.endInstant);
      if (endDay.isBefore(today)) continue; // bereits vorbei
      if (next == null || _localDay(trip.startInstant).isBefore(_localDay(next.startInstant))) {
        next = trip;
      }
    }

    if (next == null) return const TripPayload();

    final startDay = _localDay(next.startInstant);
    final endDay = _localDay(next.endInstant);
    return TripPayload(
      route: '/reisen/${next.id}',
      title: next.name,
      dateLabel: next.allDay
          ? formatDayRange(startDay, endDay)
          : formatInstantRangeInZone(
              next.startInstant,
              next.endInstant,
              next.timezone,
            ),
      daysUntil: daysBetween(today, startDay),
    );
  }

  bool get isEmpty => route == null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'route': route,
    'title': title,
    'dateLabel': dateLabel,
    'daysUntil': daysUntil,
  };
}

/// Lokaler Tagesbeginn für Kalendervergleiche.
DateTime _localDay(DateTime instant) {
  final local = instant.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Route für einen Kalender-Eintrag, abhängig vom Typ.
String? _todayRoute(CalendarEntry entry) {
  switch (entry.type) {
    case CalendarEntryType.calendarEvent:
      return '/kalender/${entry.id}';
    case CalendarEntryType.travelEvent:
      return '/reisen/einzelevent/${entry.id}';
    case CalendarEntryType.trip:
      return '/reisen/${entry.id}';
    case CalendarEntryType.ptJourney:
      return '/reisen/pt/${entry.id}';
    case CalendarEntryType.birthday:
      final userId = entry.targetId;
      return userId == null ? null : '/kontakte/$userId';
    default:
      return null;
  }
}

String _typeFallback(String type) {
  switch (type) {
    case CalendarEntryType.calendarEvent:
      return 'Termin';
    case CalendarEntryType.travelEvent:
      return 'Event';
    case CalendarEntryType.trip:
      return 'Reise';
    case CalendarEntryType.birthday:
      return 'Geburtstag';
    case CalendarEntryType.ptJourney:
      return 'Fahrt';
    default:
      return 'Termin';
  }
}
