import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Returns an [ImageProvider] for the given [imageUrl].
///
/// Supports HTTP(S) URLs and base64-encoded data URIs
/// (e.g. `data:image/png;base64,...`).
/// Returns `null` when [imageUrl] is `null` or empty.
ImageProvider? resolveImageProvider(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return null;

  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return NetworkImage(imageUrl);
  }

  if (imageUrl.startsWith('data:')) {
    final data = _decodeBase64DataUri(imageUrl);
    if (data != null) return MemoryImage(data);
  }

  // Fallback: Try decoding as raw base64
  try {
    return MemoryImage(base64.decode(imageUrl));
  } catch (_) {
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
  } catch (_) {
    // Ignore decoding errors
  }

  return null;
}
