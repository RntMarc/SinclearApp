import 'dart:async';
import 'package:http/http.dart' as http;

/// Lightweight OpenGraph metadata fetched from a URL.
class OgData {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;

  const OgData({this.title, this.description, this.imageUrl, this.siteName});
}

/// Fetches OpenGraph `<meta>` tags from a URL without any heavy dependencies.
class OgHelper {
  OgHelper._();

  static final _cache = <String, OgData>{};

  /// Fetches OG metadata for [url]. Results are cached in memory.
  static Future<OgData> fetch(String url) async {
    final cached = _cache[url];
    if (cached != null) return cached;

    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () => http.Response('', 408),
      );
      if (response.statusCode != 200) {
        const data = OgData();
        _cache[url] = data;
        return data;
      }

      final html = response.body;
      final data = _parseOg(html);
      _cache[url] = data;
      return data;
    } catch (_) {
      const data = OgData();
      _cache[url] = data;
      return data;
    }
  }

  static OgData _parseOg(String html) {
    String? extract(String property) {
      // Match <meta property="og:..." content="..." />
      final pattern = RegExp(
        '<meta[^>]*property=["\']$property["\'][^>]*content=["\']([^"\']*)["\']',
        caseSensitive: false,
      );
      final m = pattern.firstMatch(html);
      if (m != null) return m.group(1);

      // Also try content before property (content="..." property="og:...")
      final pattern2 = RegExp(
        '<meta[^>]*content=["\']([^"\']*)["\'][^>]*property=["\']$property["\']',
        caseSensitive: false,
      );
      final m2 = pattern2.firstMatch(html);
      if (m2 != null) return m2.group(1);

      return null;
    }

    return OgData(
      title: extract('og:title'),
      description: extract('og:description'),
      imageUrl: extract('og:image'),
      siteName: extract('og:site_name'),
    );
  }
}
