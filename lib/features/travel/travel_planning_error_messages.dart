import '../../core/network/api_client.dart';

/// Übersetzt die Fehlercodes der Planungs-Endpunkte in deutsche Meldungen.
///
/// Spiegel der `TravelPlanningError`-Zuordnung der API (siehe
/// `docs/travel/readme.md`); unbekannte Codes fallen auf die Server-Nachricht
/// bzw. eine generische Meldung zurück.
String planningErrorMessage(ApiException error) {
  return switch (error.errorCode) {
    'forbidden' => 'Dafür fehlt dir die Berechtigung.',
    'invalid_planning_trip' => 'Diese Reise ist keine Planungsreise (mehr).',
    'planning_trip_not_found' => 'Die Planung wurde nicht gefunden.',
    'member_not_found' => 'Das Mitglied wurde nicht gefunden.',
    'date_option_not_found' => 'Der Terminvorschlag wurde nicht gefunden.',
    'accommodation_option_not_found' =>
      'Die Unterkunftsoption wurde nicht gefunden.',
    'event_suggestion_not_found' => 'Der Eventvorschlag wurde nicht gefunden.',
    'accommodation_not_found' => 'Die Unterkunft wurde nicht gefunden.',
    'user_not_found' => 'Der Nutzer wurde nicht gefunden.',
    'already_member' => 'Diese Person ist bereits Teil der Planung.',
    'trip_already_active' => 'Die Reise ist bereits aktiv.',
    'last_leader' => 'Die letzte Leitung kann nicht entfernt werden.',
    'name_required' => 'Bitte gib einen Namen an.',
    'no_fields_to_update' => 'Es wurden keine Änderungen vorgenommen.',
    'invalid_role' => 'Die Rolle ist ungültig.',
    'invalid_topic' => 'Die Phase ist ungültig.',
    'invalid_topic_status' => 'Der Phasenstatus ist ungültig.',
    'invalid_member_status' => 'Der Mitgliedsstatus ist ungültig.',
    'invalid_response' => 'Die Rückmeldung ist ungültig.',
    'invalid_availability' => 'Die Verfügbarkeit ist ungültig.',
    'invalid_interest' => 'Das Interesse ist ungültig.',
    'invalid_direction' => 'Die Fahrtrichtung ist ungültig.',
    'user_id_required' => 'Bitte wähle eine Person aus.',
    'invalid_price' => 'Der Preis ist ungültig.',
    'invalid_timezone' => 'Die Zeitzone ist ungültig.',
    'date_required' => 'Bitte gib Start- und Enddatum an.',
    'invalid_date' => 'Das Datum ist ungültig.',
    'invalid_time_range' => 'Das Ende liegt vor dem Beginn.',
    'time_required' => 'Bitte gib Start- und Endzeit an.',
    'invalid_datetime' => 'Die Zeitangabe ist ungültig.',
    _ =>
      error.message?.isNotEmpty == true
          ? error.message!
          : 'Die Aktion ist fehlgeschlagen.',
  };
}
