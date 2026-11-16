import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Schützt davor, dass die lokale `.env` mit Deploy-Zugangsdaten wieder als
/// Asset in App- oder Web-Builds landet.
void main() {
  test('pubspec bündelt nicht die lokale .env', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec.contains('- .env'), isFalse);
    expect(pubspec.contains('- assets/env'), isTrue);
  });

  test('öffentliche Client-Konfiguration enthält keine Deploy-Secrets', () {
    final config = File('assets/env').readAsStringSync();

    expect(config.contains('API_BASE_URL='), isTrue);
    for (final secret in [
      'FTP_HOST',
      'FTP_USER',
      'FTP_PASS',
      'FTP_PROJECT_ROOT_PATH',
      'PREVIEW_FTP_PROJECT_ROOT_PATH',
    ]) {
      expect(
        config.contains(secret),
        isFalse,
        reason: '$secret darf nicht im Client-Build landen',
      );
    }
  });
}
