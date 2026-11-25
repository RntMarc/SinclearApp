import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gewünschte Bildqualität für Netzwerk-Medien.
enum MediaQuality {
  /// Automatisch: volle Qualität; bei langsamer Verbindung auf Vorschaubilder
  /// umschalten.
  auto,

  /// Datensparmodus: immer Vorschaubilder, volle Qualität nur auf Wunsch.
  low,

  /// Immer volle Qualität laden.
  high,
}

extension MediaQualityX on MediaQuality {
  String get label => switch (this) {
    MediaQuality.auto => 'Automatisch',
    MediaQuality.low => 'Datensparmodus',
    MediaQuality.high => 'Immer volle Qualität',
  };

  String get description => switch (this) {
    MediaQuality.auto =>
      'Vorschau bei schlechter Verbindung, sonst volle Qualität',
    MediaQuality.low =>
      'Immer Vorschaubilder; einzelne Bilder auf Wunsch in voller Qualität',
    MediaQuality.high => 'Bilder immer in voller Qualität laden',
  };

  IconData get icon => switch (this) {
    MediaQuality.auto => Icons.network_check_rounded,
    MediaQuality.low => Icons.data_saver_on_rounded,
    MediaQuality.high => Icons.hd_rounded,
  };
}

/// Lokale Persistenz der gewählten Bildqualität.
class MediaQualityPreference {
  const MediaQualityPreference._();

  static const _key = 'beyond.media_quality';

  static Future<MediaQuality> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    return MediaQuality.values.asNameMap()[name] ?? MediaQuality.auto;
  }

  static Future<void> save(MediaQuality value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.name);
  }
}

/// Ein [ValueNotifier], der jede Änderung automatisch persistiert. Dient als
/// einzige Quelle der Wahrheit für die aktive Bildqualität (siehe [AppScope]).
class MediaQualityController extends ValueNotifier<MediaQuality> {
  MediaQualityController(super.value);

  @override
  set value(MediaQuality newValue) {
    if (newValue == value) return;
    super.value = newValue;
    unawaited(MediaQualityPreference.save(newValue));
  }
}
