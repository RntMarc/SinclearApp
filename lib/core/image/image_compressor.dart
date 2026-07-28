import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';

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
final _log = Logger('image');

/// Returns `null` if the bytes cannot be decoded as an image,
/// or `null` when the result still exceeds 200 KB after aggressive
/// down-scaling (caller should show an error).
Uint8List? compressImage(
  Uint8List bytes, {
  int maxDimension = _defaultMaxDimension,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    _log.warning(
      'compressImage: decode failed, input=${bytes.length}B',
    );
    return null;
  }

  _log.info(
    'compressImage: original=${bytes.length}B, '
    'dims=${decoded.width}x${decoded.height}, '
    'maxDim=$maxDimension',
  );

  var resized = decoded;
  if (decoded.width > maxDimension || decoded.height > maxDimension) {
    resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxDimension : null,
      height: decoded.height >= decoded.width ? maxDimension : null,
      interpolation: img.Interpolation.linear,
    );
    _log.fine(
      'compressImage: resized to ${resized.width}x${resized.height}',
    );
  }

  var quality = _initialQuality;
  Uint8List? lastEncoded;

  while (quality >= _minQuality) {
    final encoded = Uint8List.fromList(
      img.encodeJpg(resized, quality: quality),
    );
    _log.fine(
      'compressImage: quality=$quality, size=${encoded.length}B',
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
    _log.fine(
      'compressImage: aggressive scale ${downscaled.width}x'
      '${downscaled.height}, size=${encoded.length}B',
    );
    if (encoded.length <= _maxBytes) return encoded;
  }

  // Last resort: return best-effort or null when way too big.
  if (lastEncoded != null && lastEncoded.length <= _maxBytes * 1.25) {
    _log.info(
      'compressImage: returning best-effort (${lastEncoded.length}B)',
    );
    return lastEncoded;
  }

  _log.severe(
    'compressImage: FAILED – cannot compress below 200 KB',
  );
  return null;
}
