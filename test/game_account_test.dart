import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/games/utils/game_account.dart';

void main() {
  group('normalizeMinecraftAccountId', () {
    test('akzeptiert UUIDs mit Bindestrichen', () {
      const uuid = 'ca48cfb5-bfcb-4f25-bbbf-966cb5892c80';
      expect(normalizeMinecraftAccountId(uuid), uuid);
    });

    test('akzeptiert UUIDs ohne Bindestriche', () {
      const uuid = 'CA48CFB5BFCB4F25BBBF966CB5892C80';
      expect(normalizeMinecraftAccountId(uuid), uuid);
    });

    test('akzeptiert Mojang-Usernamen', () {
      expect(normalizeMinecraftAccountId(' Notch '), 'Notch');
      expect(normalizeMinecraftAccountId('player_1'), 'player_1');
    });

    test('lehnt ungültige Eingaben ab', () {
      expect(normalizeMinecraftAccountId(''), isNull);
      expect(normalizeMinecraftAccountId('ab'), isNull);
      expect(normalizeMinecraftAccountId('name-with-dash'), isNull);
      expect(normalizeMinecraftAccountId('this_name_is_too_long'), isNull);
    });
  });

  group('normalizeGameAccountId', () {
    test('behält das Steam-Verhalten bei', () {
      expect(normalizeGameAccountId('deadlock', '179673173'), '179673173');
      expect(normalizeGameAccountId('deadlock', '76561197960265770'), '42');
    });

    test('nutzt für Minecraft die UUID-/Username-Prüfung', () {
      expect(normalizeGameAccountId('minecraft', 'Notch'), 'Notch');
      expect(normalizeGameAccountId('minecraft', 'nope!'), isNull);
    });
  });

  test('Account-Label ist spielabhängig', () {
    expect(gameAccountIdLabel('deadlock'), 'Steam-ID');
    expect(gameAccountIdLabel('minecraft'), 'UUID');
  });
}
