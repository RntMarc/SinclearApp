import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/user/models/user_public_models.dart';

void main() {
  group('UserBasePublic.isCloseFriend', () {
    Map<String, dynamic> sample() => {
      'id': 'user-1',
      'displayName': 'max',
      'image': null,
      'discordId': null,
      'discordAvatarHash': null,
      'isAdmin': false,
      'createdAt': '2026-08-01 12:00:00',
      'onboardingCompleted': false,
    };

    test('bool true wird übernommen', () {
      final json = sample()..['isCloseFriend'] = true;
      expect(UserBasePublic.fromJson(json).isCloseFriend, isTrue);
    });

    test('fehlendes Feld fällt auf false zurück', () {
      expect(UserBasePublic.fromJson(sample()).isCloseFriend, isFalse);
    });

    test('int 1/0 werden als bool gelesen', () {
      expect(
        UserBasePublic.fromJson(sample()..['isCloseFriend'] = 1).isCloseFriend,
        isTrue,
      );
      expect(
        UserBasePublic.fromJson(sample()..['isCloseFriend'] = 0).isCloseFriend,
        isFalse,
      );
    });
  });
}
