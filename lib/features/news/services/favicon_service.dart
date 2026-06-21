class FaviconService {
  static const _ddgBase = 'https://icons.duckduckgo.com/ip3';

  String resolveFaviconUrl(String articleUrl) {
    try {
      final domain = Uri.parse(articleUrl).host;
      if (domain.isEmpty) return '';
      return '$_ddgBase/$domain.ico';
    } catch (_) {
      return '';
    }
  }
}
