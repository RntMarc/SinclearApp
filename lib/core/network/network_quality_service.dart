import 'package:flutter/foundation.dart';

import '../../features/settings/models/media_quality_preference.dart';

/// Bündelt die Bildqualitäts-Präferenz des Nutzers mit einer automatisch
/// erkannten „schlechten Verbindung“.
///
/// Der [ApiClient] meldet hier Timeouts und langsame Verbindungen; die
/// Bild-Widgets und der Client lesen [lowData] ab, um zu entscheiden, ob
/// Vorschaubilder angefordert bzw. angezeigt werden sollen.
///
/// - Präferenz [MediaQuality.low]  → immer Low-Data.
/// - Präferenz [MediaQuality.high] → nie Low-Data.
/// - Präferenz [MediaQuality.auto] → Low-Data, solange die Verbindung als
///   schlecht gilt ([degraded]). Nach einem gemeldeten Fehler bleibt der
///   Zustand für ein Abklingfenster bestehen, damit es nicht zu einem
///   Wechsel zwischen voll/vorschau bei jedem einzelnen Request kommt.
class NetworkQualityService extends ChangeNotifier {
  NetworkQualityService(this.preference) {
    preference.addListener(notifyListeners);
  }

  /// Aktive Bildqualitäts-Präferenz (persistiert).
  final ValueNotifier<MediaQuality> preference;

  static const Duration _degradeWindow = Duration(minutes: 5);

  DateTime? _degradedUntil;

  /// Ob die Verbindung derzeit als schlecht gilt.
  bool get degraded {
    final until = _degradedUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  /// Ob Anfragen mit Vorschaubildern (`X-Media-Quality: low`) laufen sollen.
  bool get lowData => switch (preference.value) {
    MediaQuality.low => true,
    MediaQuality.high => false,
    MediaQuality.auto => degraded,
  };

  /// Meldet eine schlechte Verbindung (Timeout, Verbindungsfehler).
  void reportSlow() {
    _degradedUntil = DateTime.now().add(_degradeWindow);
    notifyListeners();
  }

  /// Meldet eine funktionierende Verbindung und hebt die Degradierung auf.
  void reportOk() {
    if (_degradedUntil == null) return;
    _degradedUntil = null;
    notifyListeners();
  }

  @override
  void dispose() {
    preference.removeListener(notifyListeners);
    super.dispose();
  }
}
