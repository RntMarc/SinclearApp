import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/features/chat/services/centrifugo_service.dart';

void main() {
  test('decodePayload round-trips a JSON publication payload', () {
    final encoded = CentrifugoService.encodePayload({
      'type': 'typing',
      'typing': true,
    });
    expect(CentrifugoService.decodePayload(encoded), {
      'type': 'typing',
      'typing': true,
    });
  });

  test('decodePayload returns null for empty or non-object payloads', () {
    expect(CentrifugoService.decodePayload(const []), isNull);
    expect(CentrifugoService.decodePayload(const [1, 2, 3]), isNull);
    // Gültiges JSON, aber kein Objekt (Array) -> null.
    expect(CentrifugoService.decodePayload(utf8.encode('[1,2]')), isNull);
  });

  test('withPublisherUserId ergänzt den Absender aus dem Publication-Info', () {
    // Typing-Payload ohne userId (vom Publish-Proxy sanitized).
    final enriched = CentrifugoService.withPublisherUserId(const {
      'typing': true,
    }, 'user-42');
    expect(enriched['userId'], 'user-42');
    expect(enriched['typing'], isTrue);
  });

  test('withPublisherUserId überschreibt vorhandenes userId nicht', () {
    final enriched = CentrifugoService.withPublisherUserId(const {
      'type': 'read',
      'userId': 'original',
    }, 'other');
    expect(enriched['userId'], 'original');
  });

  test('withPublisherUserId ohne Publisher bleibt unverändert', () {
    final data = CentrifugoService.withPublisherUserId(const {
      'typing': true,
    }, null);
    expect(data.containsKey('userId'), isFalse);
  });
}
