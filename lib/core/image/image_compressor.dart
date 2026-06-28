import 'dart:typed_data';

import 'package:image/image.dart' as img;

const int _maxDimension = 1000;
const int _maxBytes = 200 * 1024;
const int _initialQuality = 85;
const int _minQuality = 20;
const int _qualityStep = 10;

/// Compresses image bytes to fit the API constraints:
/// max 1000×1000 px and max 200 KB.
///
/// Returns null if the image cannot be decoded.
Uint8List? compressImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  var resized = decoded;
  if (decoded.width > _maxDimension ||
      decoded.height > _maxDimension) {
    resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? _maxDimension : null,
      height: decoded.height >= decoded.width ? _maxDimension : null,
      interpolation: img.Interpolation.linear,
    );
  }

  var quality = _initialQuality;
  while (quality >= _minQuality) {
    final encoded = img.encodeJpg(resized, quality: quality);
    if (encoded.length <= _maxBytes) return Uint8List.fromList(encoded);
    quality -= _qualityStep;
  }

  return Uint8List.fromList(img.encodeJpg(resized, quality: _minQuality));
}
