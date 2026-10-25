import 'package:url_launcher/url_launcher.dart';

/// Launches a URL in the device's external browser application.
Future<void> launchExternalUrl(String rawUrl) async {
  var url = rawUrl.trim();
  if (url.isEmpty) return;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  final uri = Uri.tryParse(url);
  if (uri != null) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// A run of text that is either plain prose (`url` is `null`) or a link.
typedef UrlSegment = ({String text, String? url});

/// Matches complete `http(s)://` URLs up to the next whitespace or angle
/// bracket. Bare hosts such as `www.example.com` are deliberately not links.
final RegExp _urlPattern = RegExp(r'https?://[^\s<>]+', caseSensitive: false);

const String _trailingPunctuation = '.,;:!?…"\'”’»';
const String _brackets = '()[]{}';

/// Splits [text] into plain and link segments.
///
/// Sentence punctuation at the end of a URL stays plain text, while balanced
/// brackets remain part of the URL (`…/Alpha_(Begriff)` keeps its closing
/// parenthesis). Concatenating all segment texts reproduces [text] exactly,
/// so callers can render prose and links without losing characters.
///
/// Only fully qualified `http://` / `https://` URLs are detected.
List<UrlSegment> splitUrlSegments(String text) {
  final segments = <UrlSegment>[];
  var cursor = 0;
  for (final match in _urlPattern.allMatches(text)) {
    final candidate = _trimTrailingPunctuation(match.group(0)!);
    final uri = Uri.tryParse(candidate);
    if (candidate.isEmpty || uri == null || uri.host.isEmpty) continue;
    if (match.start > cursor) {
      segments.add((text: text.substring(cursor, match.start), url: null));
    }
    segments.add((text: candidate, url: candidate));
    cursor = match.start + candidate.length;
  }
  if (cursor < text.length) {
    segments.add((text: text.substring(cursor), url: null));
  }
  return segments;
}

/// Returns the first link detected in [text], or `null` when there is none.
String? firstUrlIn(String text) {
  for (final segment in splitUrlSegments(text)) {
    if (segment.url != null) return segment.url;
  }
  return null;
}

String _trimTrailingPunctuation(String url) {
  var end = url.length;
  while (end > 0 && _isTrailingPunctuation(url, end)) {
    end--;
  }
  return url.substring(0, end);
}

bool _isTrailingPunctuation(String url, int end) {
  final char = url[end - 1];
  if (_trailingPunctuation.contains(char)) return true;
  final bracketIndex = _brackets.indexOf(char);
  if (bracketIndex < 0 || bracketIndex.isEven) return false;
  return _count(url, _brackets[bracketIndex - 1], end) < _count(url, char, end);
}

int _count(String text, String char, int end) {
  var count = 0;
  for (var i = 0; i < end; i++) {
    if (text[i] == char) count++;
  }
  return count;
}
