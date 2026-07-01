/// Spotify URL parsing and oEmbed data fetching.
class SpotifyHelper {
  SpotifyHelper._();

  static final _itemPattern = RegExp(
    r'open\.spotify\.com/(track|album|playlist)/([A-Za-z0-9]+)',
  );

  /// Parses a Spotify URL and returns a [SpotifyItem] or `null`.
  static SpotifyItem? parseUrl(String url) {
    final m = _itemPattern.firstMatch(url);
    if (m == null) return null;
    return SpotifyItem(type: m.group(1)!, id: m.group(2)!);
  }

  /// Builds the Spotify embed iframe URL for a given track/album/playlist.
  static String embedUrl(String type, String id) =>
      'https://open.spotify.com/embed/$type/$id?utm_source=generator&theme=0';
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
