import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/settings/models/dav_token_models.dart';

void main() {
  group('DavToken.fromJson', () {
    test('parst alle Felder der Liste', () {
      final token = DavToken.fromJson({
        'id': 'token-1',
        'label': 'DAVx5 – Pixel 8',
        'expiresAt': '2027-08-14 12:00:00',
        'lastUsedAt': '2026-08-14 08:00:00',
        'createdAt': '2026-08-14 12:00:00',
      });
      expect(token.id, 'token-1');
      expect(token.label, 'DAVx5 – Pixel 8');
      expect(token.lastUsedAt, '2026-08-14 08:00:00');
    });

    test('lastUsedAt darf fehlen', () {
      final token = DavToken.fromJson({
        'id': 'token-1',
        'label': 'Neu',
        'expiresAt': '2027-08-14 12:00:00',
        'lastUsedAt': null,
        'createdAt': '2026-08-14 12:00:00',
      });
      expect(token.lastUsedAt, isNull);
    });
  });

  test('DavTokenCreateResult parst das einmalige Token', () {
    final result = DavTokenCreateResult.fromJson({
      'id': 'token-1',
      'label': 'Thunderbird',
      'token': 'dav_abc123',
      'expiresAt': '2027-08-14 12:00:00',
      'createdAt': '2026-08-14 12:00:00',
    });
    expect(result.token, 'dav_abc123');
    expect(result.label, 'Thunderbird');
  });
}
