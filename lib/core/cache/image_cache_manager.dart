import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheManager {
  ImageCacheManager._();

  static final ImageCacheManager instance = ImageCacheManager._();

  static final CacheManager faviconCache = CacheManager(
    Config(
      'favicons',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 500,
    ),
  );

  static final CacheManager previewCache = CacheManager(
    Config(
      'previews',
      stalePeriod: const Duration(days: 2),
      maxNrOfCacheObjects: 200,
    ),
  );
}
