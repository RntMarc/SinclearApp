import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sinclear_beyond/core/network/api_client.dart';

void main() {
  test('dekodiert JSON-Antworten ohne charset-Header als UTF-8', () async {
    // `response.body` nimmt ohne charset im Content-Type latin1 an — Umlaute
    // würden zu Mojibake („SchÃ¶n“). Der Client muss explizit UTF-8
    // dekodieren, da JSON laut RFC 8259 immer UTF-8 ist.
    final client = MockClient((request) async {
      final bytes = utf8.encode(
        '{"title":"Neue Story","text":"Jemand hat eine neue Story veröffentlicht."}',
      );
      return http.Response.bytes(
        bytes,
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ApiClient(baseUrl: 'https://example.test', client: client);

    final response = await api.get('/notifications');

    expect(response['title'], 'Neue Story');
    expect(
      response['text'],
      'Jemand hat eine neue Story veröffentlicht.',
    );
  });

  test('wirft bei Nicht-2xx trotz UTF-8-Dekodierung eine ApiException',
      () async {
    final client = MockClient((request) async {
      final bytes = utf8.encode('{"error":"ungültig","message":"Grüße"}');
      return http.Response.bytes(
        bytes,
        400,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ApiClient(baseUrl: 'https://example.test', client: client);

    await expectLater(
      api.get('/stories'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'Grüße')
            .having((e) => e.statusCode, 'statusCode', 400),
      ),
    );
  });
}
