import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sinclear_beyond/core/image/image_provider_helper.dart';

void main() {
  group('resolveImageProvider', () {
    test('liefert null für leere oder ungültige Quellen', () {
      expect(resolveImageProvider(null), isNull);
      expect(resolveImageProvider(''), isNull);
      expect(resolveImageProvider('!!kein-base64!!'), isNull);
    });

    test('HTTP-URL ergibt NetworkImage', () {
      expect(
        resolveImageProvider('https://example.com/avatar.png'),
        isA<NetworkImage>(),
      );
    });

    test('decodiert Base64 und reused dieselben Bytes (kein Flackern)', () {
      final source = base64.encode(const [1, 2, 3, 4]);
      final first = resolveImageProvider(source) as MemoryImage;
      final second = resolveImageProvider(source) as MemoryImage;

      expect(first.bytes, [1, 2, 3, 4]);
      expect(identical(first.bytes, second.bytes), isTrue);
    });

    test('decodiert data: URI und cached', () {
      final source = 'data:image/png;base64,${base64.encode(const [9, 8, 7])}';
      final provider = resolveImageProvider(source);

      expect(provider, isA<MemoryImage>());
      expect((provider as MemoryImage).bytes, [9, 8, 7]);
    });

    test('unterschiedliche Quellen ergeben unterschiedliche Bytes', () {
      final a =
          resolveImageProvider(base64.encode(const [1, 2])) as MemoryImage;
      final b =
          resolveImageProvider(base64.encode(const [3, 4])) as MemoryImage;

      expect(identical(a.bytes, b.bytes), isFalse);
    });
  });
}
