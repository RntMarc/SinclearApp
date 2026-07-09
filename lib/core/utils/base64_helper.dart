import 'dart:convert';
import 'dart:typed_data';

/// Decodes a base-64 string, stripping any data-URL prefix
/// (e.g. `data:image/png;base64,...`).
Uint8List decodeBase64Image(String base64String) {
  final cleaned = base64String.contains(',')
      ? base64String.split(',').last
      : base64String;
  return base64Decode(cleaned);
}
