import 'package:flutter/material.dart';

class NotificationTypeLabel {
  static String title(String type) {
    return switch (type) {
      'recipe_review' => 'Neue Bewertung',
      'new_trip_participant' => 'Neuer Teilnehmer',
      'trip_updated' => 'Reise aktualisiert',
      'event_reminder' => 'Event-Erinnerung',
      'new_friend_request' => 'Freundschaftsanfrage',
      _ => 'Benachrichtigung',
    };
  }

  static String body(String type) {
    return switch (type) {
      'recipe_review' => 'Jemand hat eine Bewertung hinterlassen.',
      'new_trip_participant' => 'Jemand ist deiner Reise beigetreten.',
      'trip_updated' => 'Eine deiner Reisen wurde aktualisiert.',
      'event_reminder' => 'Ein Event beginnt bald.',
      'new_friend_request' => 'Jemand möchte dich als Kontakt hinzufügen.',
      _ => 'Du hast eine neue Benachrichtigung.',
    };
  }

  static IconData icon(String type) {
    return switch (type) {
      'recipe_review' => Icons.star_rounded,
      'new_trip_participant' => Icons.person_add_rounded,
      'trip_updated' => Icons.flight_rounded,
      'event_reminder' => Icons.event_rounded,
      'new_friend_request' => Icons.people_rounded,
      _ => Icons.notifications_rounded,
    };
  }
}
