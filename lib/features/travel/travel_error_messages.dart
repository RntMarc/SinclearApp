import '../../core/network/api_client.dart';

/// Übersetzt die Fehlercodes der Travel-Endpunkte in deutsche Meldungen.
///
/// Einzige Stelle für die Zuordnung (API-Doku `travel`); unbekannte Codes
/// fallen auf die Server-Nachricht bzw. eine generische Meldung zurück.
String travelErrorMessage(ApiException error) {
  return switch (error.errorCode) {
    'forbidden' => 'Dafür fehlt dir die Berechtigung.',
    'conversion_not_allowed' => 'Die Konvertierung ist nicht erlaubt.',
    'trip_not_found' => 'Die Reise wurde nicht gefunden.',
    'event_not_found' => 'Das Event wurde nicht gefunden.',
    'accommodation_not_found' => 'Die Unterkunft wurde nicht gefunden.',
    'user_not_found' => 'Der Nutzer wurde nicht gefunden.',
    'ticket_not_found' => 'Das Ticket wurde nicht gefunden.',
    'already_participant' => 'Der Nutzer ist bereits Teilnehmer.',
    'last_leader' => 'Der letzte Reiseleiter kann nicht entfernt werden.',
    'name_required' => 'Bitte gib einen Namen an.',
    'trip_required' => 'Bitte wähle eine Reise aus.',
    'invalid_role' => 'Die Rolle ist ungültig.',
    'invalid_conversion' => 'Die Konvertierung ist ungültig.',
    'no_fields_to_update' => 'Es wurden keine Änderungen vorgenommen.',
    'invalid_timezone' => 'Die Zeitzone ist ungültig.',
    'date_required' => 'Bitte gib Start- und Enddatum an.',
    'invalid_date' => 'Das Datum ist ungültig.',
    'invalid_time_range' => 'Das Ende liegt vor dem Beginn.',
    'time_required' => 'Bitte gib Start- und Endzeit an.',
    'invalid_datetime' => 'Die Zeitangabe ist ungültig.',
    'invalid_image' => 'Das Bild ist ungültig oder zu groß.',
    _ =>
      error.message?.isNotEmpty == true
          ? error.message!
          : 'Die Aktion ist fehlgeschlagen.',
  };
}
