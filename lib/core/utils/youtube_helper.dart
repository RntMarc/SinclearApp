/// Utilities for extracting YouTube video IDs from URLs and building
/// thumbnail/embed URLs.
class YoutubeHelper {
  YoutubeHelper._();

  static final _patterns = [
    RegExp(r'(?:youtube\.com/watch\?.*v=|youtu\.be/|youtube\.com/shorts/|youtube\.com/embed/)([A-Za-z0-9_-]{11})'),
  ];

  /// Returns the 11-character video ID or `null` if the URL is not a valid
  /// YouTube link.
  static String? extractVideoId(String url) {
    for (final p in _patterns) {
      final m = p.firstMatch(url);
      if (m != null) return m.group(1);
    }
    return null;
  }

  /// YouTube static thumbnail URL (hqdefault).
  static String thumbnailUrl(String videoId) =>
      'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

  /// YouTube embed URL for use in iframes / WebView.
  static String embedUrl(String videoId) =>
      'https://www.youtube.com/embed/$videoId';
}
