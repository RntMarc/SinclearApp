import '../../core/network/api_client.dart';

/// Übersetzt die Fehlercodes der Poll-Endpunkte in deutsche Meldungen.
///
/// Einzige Stelle für die Zuordnung (API-Doku `polls`); unbekannte Codes
/// fallen auf die Server-Nachricht bzw. eine generische Meldung zurück.
String pollErrorMessage(ApiException error) {
  return switch (error.errorCode) {
    'forbidden' => 'Dafür fehlt dir die Berechtigung.',
    'not_found' => 'Die Umfrage wurde nicht gefunden.',
    'poll_closed' => 'Die Umfrage ist geschlossen.',
    'already_voted' => 'Du hast bereits abgestimmt.',
    'already_responded' => 'Du hast bereits geantwortet.',
    'results_hidden' => 'Die Ergebnisse sind noch nicht sichtbar.',
    'counter_proposals_disabled' =>
      'Gegenvorschläge sind für diese Umfrage deaktiviert.',
    'invalid_answer' => 'Die Antwort ist ungültig.',
    'answer_required' => 'Bitte beantworte alle Pflichtfragen.',
    'invalid_config' => 'Die Frage-Konfiguration ist ungültig.',
    'invalid_option' => 'Die gewählte Option ist ungültig.',
    'title_required' => 'Bitte gib einen Titel an.',
    'time_forbidden' => 'Uhrzeiten sind für diesen Eintrag nicht erlaubt.',
    'date_forbidden' => 'Datumsfelder sind für diesen Eintrag nicht erlaubt.',
    'invalid_target' => 'Der ausgewählte Nutzer ist ungültig.',
    _ =>
      error.message?.isNotEmpty == true
          ? error.message!
          : 'Die Aktion ist fehlgeschlagen.',
  };
}
