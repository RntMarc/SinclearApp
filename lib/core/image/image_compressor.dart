import 'dart:developer' as developer;
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

  developer.log(
    'compressImage: original=${bytes.length}B, '
    'dims=${decoded.width}x${decoded.height}',
    name: 'image',
  );

  var resized = decoded;
  if (decoded.width > _maxDimension ||
      decoded.height > _maxDimension) {
    resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? _maxDimension : null,
      height: decoded.height >= decoded.width ? _maxDimension : null,
      interpolation: img.Interpolation.linear,
    );
    developer.log(
      'compressImage: resized to ${resized.width}x${resized.height}',
      name: 'image',
    );
  }

  var quality = _initialQuality;
  Uint8List? lastEncoded;

  while (quality >= _minQuality) {
    final encoded = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    developer.log(
      'compressImage: quality=$quality, size=${encoded.length}B',
      name: 'image',
    );
    if (encoded.length <= _maxBytes) return encoded;
    lastEncoded = encoded;
    quality -= _qualityStep;
  }

  // If even at minQuality it's too large, we might need to downscale further,
  // but for now we return the best we have or null if it's still way too big.
  if (lastEncoded != null && lastEncoded.length <= _maxBytes * 1.5) {
    developer.log(
      'compressImage: returning slightly oversized image (${lastEncoded.length}B)',
      name: 'image',
    );
    return lastEncoded;
  }

  final encoded = Uint8List.fromList(img.encodeJpg(resized, quality: _minQuality));
  developer.log(
    'compressImage: final quality=$_minQuality, size=${encoded.length}B',
    name: 'image',
  );
  return Uint8List.fromList(encoded);
}
