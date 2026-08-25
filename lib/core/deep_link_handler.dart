import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles incoming deep links and routes them appropriately.
///
/// - Discord auth callbacks open in an in-app WebView to show the pairing code
///   (external browser is intercepted by Android App Links).
/// - Recipe HTML URLs extract the recipe ID and navigate in-app.
/// - Other API URLs are forwarded to the external browser.
/// - All other links are ignored.
class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  GoRouter? _router;

  /// Start listening for deep links.
  void init(GoRouter router, {required String appBaseUrl}) {
    _router = router;

    _appLinks.getInitialLink().then(_handleUri);

    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object e) {
        developer.log('app_links stream error', error: e);
      },
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;

    final urlString = uri.toString();
    final path = uri.path;

    // Discord auth callbacks: open in in-app WebView to show pairing code HTML page.
    // Using externalApplication triggers Android App Links which opens the app again (loop).
    if (_isDiscordCallback(path)) {
      _openInWebView(uri);
      return;
    }

    // Other API URLs: forward to external browser
    if (urlString.startsWith('https://sinclear.de/api/v2')) {
      _openInBrowser(uri);
      return;
    }

    // Recipe HTML URLs: extract ID and navigate in-app
    final recipeId = _extractRecipeId(uri);
    if (recipeId != null) {
      _router?.go('/rezepte/$recipeId');
      return;
    }
  }

  /// Discord OAuth callback URLs (login + register).
  bool _isDiscordCallback(String path) {
    return path.contains('/auth/') && path.contains('/discord/callback');
  }

  /// Recipe HTML URLs look like `/api/v2/html/public/recipe?id=…`.
  /// Extract the `id` query parameter so we can navigate in-app.
  String? _extractRecipeId(Uri uri) {
    if (!uri.path.contains('/html/public/recipe')) return null;
    return uri.queryParameters['id'];
  }

  /// Open URL in external browser.
  Future<void> _openInBrowser(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Open URL in an in-app WebView (Chrome Custom Tab on Android).
  /// Used for auth callbacks to show the pairing code without App Links interception.
  Future<void> _openInWebView(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }
}