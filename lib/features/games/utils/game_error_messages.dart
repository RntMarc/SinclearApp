import '../../../core/network/api_client.dart';

/// Übersetzt die Fehlercodes der Spiele-Endpunkte in deutsche Meldungen.
///
/// Einzige Stelle für die Zuordnung (API-Doku `games`); unbekannte Codes
/// fallen auf die Server-Nachricht bzw. eine generische Meldung zurück.
/// Mit [game] `minecraft` werden Minecraft-spezifische Texte verwendet.
String gameErrorMessage(Object error, {String? game}) {
  if (error is! ApiException) {
    return 'Die Anfrage ist fehlgeschlagen. Bitte versuche es erneut.';
  }
  final isMinecraft = game == 'minecraft';
  return switch (error.errorCode) {
    'invalid_account_id' =>
      isMinecraft
          ? 'Bitte gib eine gültige Minecraft-UUID oder einen Spielernamen '
                '(3–16 Zeichen) ein.'
          : 'Die Steam-ID ist ungültig. Erlaubt sind SteamID3 (max. 10 Ziffern) '
                'oder SteamID64.',
    'account_not_found' =>
      isMinecraft
          ? 'Zu dieser UUID bzw. diesem Spielernamen wurde kein Minecraft-Account '
                'gefunden.'
          : 'Zu dieser Steam-ID wurde kein Profil gefunden.',
    'account_already_linked' =>
      'Dieser Account ist bereits mit einem anderen Nutzer verknüpft.',
    'game_api_unavailable' =>
      'Die Spiele-API ist gerade nicht erreichbar. Bitte später erneut '
          'versuchen.',
    'unknown_game' => 'Dieses Spiel wird nicht unterstützt.',
    'game_account_not_found' => 'Für dieses Spiel ist kein Account verknüpft.',
    'missing_user_ids' => 'Es wurden keine Spieler ausgewählt.',
    'too_many_user_ids' => 'Es wurden zu viele Spieler ausgewählt.',
    'user_not_found' => 'Der Nutzer wurde nicht gefunden.',
    'forbidden' => 'Dafür fehlt dir die Berechtigung.',
    _ =>
      error.message?.isNotEmpty == true
          ? error.message!
          : 'Die Anfrage ist fehlgeschlagen.',
  };
}
