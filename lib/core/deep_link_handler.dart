import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles incoming deep links and routes them appropriately.
///
/// - Discord auth callbacks are forwarded to the external browser.
/// - Recipe HTML URLs extract the recipe ID and navigate in-app.
/// - All other links are ignored.
class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  GoRouter? _router;
  String? _appBaseUrl;

  /// Start listening for deep links.
  void init(GoRouter router, {required String appBaseUrl}) {
    _router = router;
    _appBaseUrl = appBaseUrl;

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

    final path = uri.path;

    if (_isDiscordCallback(path)) {
      _openInBrowser(uri);
      return;
    }

    final recipeId = _extractRecipeId(uri);
    if (recipeId != null) {
      _router?.go('/rezepte/$recipeId');
      return;
    }
  }

  /// Discord OAuth callback URLs should be handled by the browser, not the
  /// app. Forward them so the user can see the pairing code / confirmation.
  bool _isDiscordCallback(String path) {
    return path.contains('/auth/') && path.contains('/discord/callback');
  }

  /// Recipe HTML URLs look like `/api/v2/html/public/recipe?id=…`.
  /// Extract the `id` query parameter so we can navigate in-app.
  String? _extractRecipeId(Uri uri) {
    if (!uri.path.contains('/html/public/recipe')) return null;
    return uri.queryParameters['id'];
  }

  Future<void> _openInBrowser(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
