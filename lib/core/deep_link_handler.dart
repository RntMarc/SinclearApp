import 'dart:async';
import 'dart:developer' as developer;

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

/// Handles incoming deep links and routes them to the matching app route.
///
/// The Android intent filter (AndroidManifest.xml) only claims the app's own
/// paths plus the public recipe HTML page, so everything reaching this handler
/// is either an app route or a recipe link. API URLs (e.g. the Discord OAuth
/// callback) never reach the app — they stay in the browser.
///
/// - Recipe HTML URLs (`/api/v2/html/public/recipe?id=…`) navigate to
///   `/rezepte/:id`.
/// - All other URLs map their path + query to the matching go_router route.
class DeepLinkHandler {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  GoRouter? _router;

  /// Start listening for deep links.
  void init(GoRouter router) {
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

    // Public recipe HTML page → open the recipe in-app.
    final recipeId = _extractRecipeId(uri);
    if (recipeId != null) {
      _router?.go('/rezepte/$recipeId');
      return;
    }

    // Every other claimed URL is an app route: strip scheme + host and
    // navigate to the path (plus query).
    var location = uri.path;
    if (uri.hasQuery) location = '$location?${uri.query}';
    if (location.isEmpty) location = '/';
    _router?.go(location);
  }

  /// Recipe HTML URLs look like `/api/v2/html/public/recipe?id=…`.
  /// Extract the `id` query parameter so we can navigate in-app.
  String? _extractRecipeId(Uri uri) {
    if (!uri.path.contains('/html/public/recipe')) return null;
    return uri.queryParameters['id'];
  }
}
