import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _log = Logger('image');

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

  if (imageUrl.startsWith('data:')) {
    final data = _decodeBase64DataUri(imageUrl);
    if (data != null) return MemoryImage(data);
    _log.warning(
      'resolveImageProvider: invalid data URI (len=${imageUrl.length})',
    );
    return null;
  }

  // Fallback: try decoding as raw base64 string.
  try {
    final decoded = base64.decode(imageUrl);
    if (decoded.isEmpty) return null;
    return MemoryImage(decoded);
  } catch (e) {
    _log.warning(
      'resolveImageProvider: base64 decode failed (len=${imageUrl.length}): $e',
    );
    return null;
  }
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
