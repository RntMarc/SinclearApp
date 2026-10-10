import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

/// Verarbeitet Taps auf die Widgets: `home_widget` liefert die Click-URI
/// (`beyond://app/…`) über [`HomeWidget.widgetClicked`] bzw.
/// [`HomeWidget.initiallyLaunchedFromHomeWidget`] — hier wird der Pfad auf
/// die passende go_router-Route abgebildet.
///
/// Die native Seite baut die URI als `beyond://app<route>` (z. B.
/// `beyond://app/kalender/123`); wir übernehmen schlicht den Pfad.
class WidgetLaunchHandler {
  StreamSubscription<Uri?>? _sub;
  GoRouter? _router;

  void init(GoRouter router) {
    _router = router;

    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handle);
    _sub = HomeWidget.widgetClicked.listen(_handle);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  void _handle(Uri? uri) {
    if (uri == null) return;
    final location = uri.path.isEmpty ? '/' : uri.path;
    _router?.go(location);
  }
}
