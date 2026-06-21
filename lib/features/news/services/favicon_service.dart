import 'dart:developer' as developer;

class FaviconService {
  static const _ddgBase = 'https://icons.duckduckgo.com/ip3';

  String resolveFaviconUrl(String articleUrl) {
    try {
      final domain = Uri.parse(articleUrl).host;
      if (domain.isEmpty) return '';
      return '$_ddgBase/$domain.ico';
    } catch (e, st) {
      developer.log('Failed to resolve favicon URL', error: e, stackTrace: st);
      return '';
    }
  }
}
