// Rechnet die üblichen Steam-ID-Formate in die von der API erwartete
// SteamID3 (Account-ID) um.
//
// Die SteamID64 liegt oberhalb von 2^53 und ist damit in JavaScript nicht
// exakt als `int` darstellbar. Deshalb wird konsequent mit BigInt gerechnet.

const String _steamId64Offset = '76561197960265728';
const int _maxAccountId = 4294967295; // 2^32 - 1

/// Parst eine SteamID3 oder SteamID64 und gibt die Account-ID als String
/// zurück. Liefert `null`, wenn die Eingabe keine gültige ID ist.
///
/// Akzeptiert werden:
/// - SteamID3/Account-ID (1 … 4294967295, z. B. `179673173`)
/// - SteamID64 (beginnt üblicherweise mit `7656119…`)
String? normalizeSteamId(String input) {
  final digits = input.trim().replaceAll(RegExp(r'\s'), '');
  if (digits.isEmpty || digits.length > 20) return null;
  if (!RegExp(r'^\d+$').hasMatch(digits)) return null;

  final value = BigInt.parse(digits);
  final account = value > BigInt.from(_maxAccountId)
      ? value - BigInt.parse(_steamId64Offset)
      : value;

  if (account < BigInt.one || account > BigInt.from(_maxAccountId)) {
    return null;
  }
  return account.toString();
}
