import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _log = Logger('image');

/// Decodierte Bild-Bytes, keyed by Quellstring, damit derselbe Bildinhalt
/// app-übergreifend auf dieselbe [Uint8List] (und damit denselben
/// [MemoryImage]) abgebildet wird. Ohne diesen Cache erzeugt jeder Rebuild
/// einen frisch decodierten Puffer, den Flutter als neues Bild behandelt —
/// das verursacht das Avatar-Flackern bei Listen-Rebuilds. Bleibt der
/// Quellstring (Base64/`data:`-URI) unverändert, wird auch nie neu gerendert.
///
/// ponytail: einfacher FIFO-Eviction statt LRU/TTL. Avatare sind der
/// Hauptnutzer; die begrenzte Nutzerzahl hält den Cache klein. Wird Speicher
/// je relevant, auf einen größenbewussten LRU keyed by Content-Hash wechseln.
final LinkedHashMap<String, Uint8List> _decodedImages = LinkedHashMap();

const int _maxDecodedImages = 256;

/// Returns an [ImageProvider] for the given [imageUrl].
///
/// Supports HTTP(S) URLs, raw base64 strings and `data:` URIs
/// (e.g. `data:image/png;base64,...`).
/// Returns `null` when [imageUrl] is `null`, empty or invalid.
ImageProvider? resolveImageProvider(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return null;

  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return NetworkImage(imageUrl);
  }

  final bytes = _decodedBytes(imageUrl);
  if (bytes == null) {
    _log.warning(
      'resolveImageProvider: invalid image source (len=${imageUrl.length})',
    );
    return null;
  }
  return MemoryImage(bytes);
}

/// Liefert die decodierten Bytes für [source] aus dem Cache oder decodiert
/// und cacht sie. `null` bei ungültiger Quelle.
Uint8List? _decodedBytes(String source) {
  final cached = _decodedImages[source];
  if (cached != null) return cached;

  Uint8List? decoded;
  if (source.startsWith('data:')) {
    decoded = _decodeBase64DataUri(source);
  } else {
    try {
      decoded = base64.decode(source);
    } catch (_) {
      decoded = null;
    }
  }
  if (decoded == null || decoded.isEmpty) return null;

  if (_decodedImages.length >= _maxDecodedImages) {
    _decodedImages.remove(_decodedImages.keys.first);
  }
  _decodedImages[source] = decoded;
  return decoded;
}

Uint8List? _decodeBase64DataUri(String dataUri) {
  try {
    final commaIndex = dataUri.indexOf(',');
    if (commaIndex == -1) return null;

    final meta = dataUri.substring(0, commaIndex);
    final payload = dataUri.substring(commaIndex + 1);

    if (meta.contains(';base64')) {
      return base64.decode(payload.trim());
    }
  } catch (e) {
    _log.warning('_decodeBase64DataUri: decode failed: $e');
  }

  return null;
}
