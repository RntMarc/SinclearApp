/// Ergebnis eines [FcmPushService.setup]-Aufrufs.
enum FcmSetupResult {
  /// Token erzeugt bzw. eine bereits registrierte Zustellung übernommen.
  ready,

  /// Der Nutzer hat die Benachrichtigungs-Berechtigung verweigert.
  permissionDenied,

  /// FCM ist auf dem Gerät nicht nutzbar (z. B. keine Google Play-Dienste).
  unavailable,

  /// Registrierung beim Sinclear-Server oder Token-Bezug fehlgeschlagen.
  failed,
}
