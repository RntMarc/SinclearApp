/// Spotify URL parsing and oEmbed data fetching.
class SpotifyHelper {
  SpotifyHelper._();

  static final _itemPattern = RegExp(
    r'open\.spotify\.com/(track|album|playlist)/([A-Za-z0-9]+)',
  );

  static final _oembedCache = <String, SpotifyOEmbedData>{};

  /// Parses a Spotify URL and returns a [SpotifyItem] or `null`.
  static SpotifyItem? parseUrl(String url) {
    final m = _itemPattern.firstMatch(url);
    if (m == null) return null;
    return SpotifyItem(type: m.group(1)!, id: m.group(2)!);
  }

  /// Builds the Spotify embed iframe URL for a given track/album/playlist.
  static String embedUrl(String type, String id) =>
      'https://open.spotify.com/embed/$type/$id?utm_source=generator&theme=0';

  /// Returns cached oEmbed data for [url], or `null` if not cached.
  static SpotifyOEmbedData? cachedOEmbed(String url) => _oembedCache[url];

  /// Stores oEmbed data in the cache.
  static void cacheOEmbed(String url, SpotifyOEmbedData data) {
    _oembedCache[url] = data;
  }
}

/// A parsed Spotify item (track, album, or playlist).
class SpotifyItem {
  final String type;
  final String id;

  const SpotifyItem({required this.type, required this.id});

  String get embedUrl => SpotifyHelper.embedUrl(type, id);

  String get label {
    switch (type) {
      case 'track':
        return 'Track';
      case 'album':
        return 'Album';
      case 'playlist':
        return 'Playlist';
      default:
        return 'Spotify';
    }
  }
}

/// Lightweight oEmbed response data.
class SpotifyOEmbedData {
  final String thumbnailUrl;
  final String title;
  final String artistName;

  const SpotifyOEmbedData({
    required this.thumbnailUrl,
    required this.title,
    required this.artistName,
  });
}
