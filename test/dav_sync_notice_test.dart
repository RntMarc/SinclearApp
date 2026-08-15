import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/settings/models/dav_sync_notice.dart';

void main() {
  group('DavSyncNotice', () {
    test('roundtrip über toJson/fromJson erhält alle Felder', () {
      final notice = DavSyncNotice(
        id: '42',
        severity: DavSyncSeverity.error,
        step: 'Token erstellen',
        message: 'HTTP 409 (token_limit)',
        createdAt: DateTime.fromMillisecondsSinceEpoch(1723700000000),
      );

      final restored = DavSyncNotice.fromJson(notice.toJson());

      expect(restored.id, '42');
      expect(restored.severity, DavSyncSeverity.error);
      expect(restored.step, 'Token erstellen');
      expect(restored.message, 'HTTP 409 (token_limit)');
      expect(restored.createdAt, notice.createdAt);
    });

    test('unbekannter Severity-Name fällt auf info zurück', () {
      final restored = DavSyncNotice.fromJson({
        'id': '1',
        'severity': 'unbekannt',
        'step': 'x',
        'message': 'y',
        'createdAt': 0,
      });
      expect(restored.severity, DavSyncSeverity.info);
    });
  });
}
