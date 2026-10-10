import 'dart:async';

import 'package:flutter/widgets.dart';

/// Stößt die Widget-Synchronisation an, wenn die App in den Hintergrund
/// wechselt. So sind die Widgets aktuell, sobald der Nutzer den Homescreen
/// (wieder) sieht — unabhängig von der gewählten Benachrichtigungs-Methode.
class WidgetSyncObserver with WidgetsBindingObserver {
  WidgetSyncObserver({required this.sync});

  /// Die auszuführende Synchronisation (z. B. `syncWidgetsHeadless`).
  final Future<void> Function() sync;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(sync());
    }
  }
}
