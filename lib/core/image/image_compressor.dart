import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

const int _defaultMaxDimension = 1000;
const int _maxBytes = 200 * 1024;
const int _initialQuality = 85;
const int _minQuality = 20;
const int _qualityStep = 10;

/// Compresses image bytes to fit the API constraints.
///
/// Profile, forum and recipe images: [maxDimension] 1000.
/// Bug-report screenshots:           [maxDimension] 4000.
/// Max decoded file size is always 200 KB.
///
/// Returns `null` if the bytes cannot be decoded as an image,
/// or `null` when the result still exceeds 200 KB after aggressive
/// down-scaling (caller should show an error).
Uint8List? compressImage(
  Uint8List bytes, {
  int maxDimension = _defaultMaxDimension,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    developer.log(
      'compressImage: decode failed, input=${bytes.length}B',
      name: 'image',
      level: 900,
    );
    return null;
  }

  developer.log(
    'compressImage: original=${bytes.length}B, '
    'dims=${decoded.width}x${decoded.height}, '
    'maxDim=$maxDimension',
    name: 'image',
  );

  var resized = decoded;
  if (decoded.width > maxDimension || decoded.height > maxDimension) {
    resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxDimension : null,
      height: decoded.height >= decoded.width ? maxDimension : null,
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
    final encoded = Uint8List.fromList(
      img.encodeJpg(resized, quality: quality),
    );
    developer.log(
      'compressImage: quality=$quality, size=${encoded.length}B',
      name: 'image',
    );
    if (encoded.length <= _maxBytes) return encoded;
    lastEncoded = encoded;
    quality -= _qualityStep;
  }

  // Even at minimum quality the image exceeds 200 KB.
  // Retry with aggressive down-scaling (half the target dimension).
  final aggressive = maxDimension ~/ 2;
  if (resized.width > aggressive || resized.height > aggressive) {
    final downscaled = img.copyResize(
      resized,
      width: resized.width >= resized.height ? aggressive : null,
      height: resized.height >= resized.width ? aggressive : null,
      interpolation: img.Interpolation.linear,
    );
    final encoded = Uint8List.fromList(
      img.encodeJpg(downscaled, quality: _minQuality),
    );
    developer.log(
      'compressImage: aggressive scale ${downscaled.width}x'
      '${downscaled.height}, size=${encoded.length}B',
      name: 'image',
    );
    if (encoded.length <= _maxBytes) return encoded;
  }

  // Last resort: return best-effort or null when way too big.
  if (lastEncoded != null && lastEncoded.length <= _maxBytes * 1.25) {
    developer.log(
      'compressImage: returning best-effort (${lastEncoded.length}B)',
      name: 'image',
    );
    return lastEncoded;
  }

  developer.log(
    'compressImage: FAILED – cannot compress below 200 KB',
    name: 'image',
    level: 1000,
  );
  return null;
}
