import 'steam_id.dart';

final RegExp _minecraftUuid32 = RegExp(r'^[0-9a-fA-F]{32}$');
final RegExp _minecraftUuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
  r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
final RegExp _minecraftUsername = RegExp(r'^[A-Za-z0-9_]{3,16}$');

/// Bezeichnung der Account-ID im jeweiligen Spiel.
String gameAccountIdLabel(String slug) =>
    slug == 'minecraft' ? 'UUID' : 'Steam-ID';

/// Beispielwert für das Eingabefeld beim Verknüpfen.
String gameAccountHint(String slug) => slug == 'minecraft'
    ? 'z. B. Notch oder ca48cfb5-bfcb-4f25-bbbf-966cb5892c80'
    : 'z. B. 76561198139938901';

/// Erklärender Hilfetext beim Verknüpfen.
String gameAccountHelp(String slug) => slug == 'minecraft'
    ? 'Minecraft-UUID (mit oder ohne Bindestriche) oder Mojang-Spielername '
          '(3–16 Zeichen: A–Z, a–z, 0–9, _).'
    : 'SteamID64 (beginnt mit 7656…) oder SteamID3/Account-ID '
          '(max. 10 Ziffern).';

/// Normalisiert die Account-Eingabe für das jeweilige Spiel.
///
/// Deadlock: SteamID3/SteamID64 → SteamID3. Minecraft: UUID oder Username
/// werden unverändert zurückgegeben; die API löst den Username auf.
String? normalizeGameAccountId(String slug, String input) => slug == 'minecraft'
    ? normalizeMinecraftAccountId(input)
    : normalizeSteamId(input);

/// Prüft eine Minecraft-UUID (32 Hex oder kanonisch) oder einen Username.
String? normalizeMinecraftAccountId(String input) {
  final value = input.trim();
  if (value.isEmpty || value.length > 36) return null;
  if (_minecraftUuid.hasMatch(value) || _minecraftUuid32.hasMatch(value)) {
    return value;
  }
  if (_minecraftUsername.hasMatch(value)) return value;
  return null;
}
