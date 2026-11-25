import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../features/auth/services/auth_service.dart';
import '../network/api_client.dart';
import '../utils/base64_helper.dart';

/// Lädt volle Bildqualität für einen Vorschaubild-Hash nach
/// (`GET /media/{hash}`) und cached sie lokal.
///
/// Der Hash ist content-addressed und damit unveränderlich; einmal geladen,
/// wird das Bild über die App-Laufzeit hinweg im Speicher und über Neustarts
/// hinweg im Disk-Cache (`DefaultCacheManager`) vorgehalten. So muss ein
/// Avatar oder Inhaltsbild nur einmal nachgeladen werden.
class MediaService {
  final ApiClient api;
  final AuthService auth;

  final Map<String, Uint8List> _memory = {};

  MediaService({required this.api, required this.auth});

  static const int _maxMemoryEntries = 128;

  /// Liefert die decodierten Bild-Bytes für [hash] oder `null`.
  Future<Uint8List?> loadFullQuality(String hash) async {
    final cachedMem = _memory[hash];
    if (cachedMem != null) return cachedMem;

    // Disk-Cache (persistiert über Neustarts; auf Web IndexedDB).
    try {
      final info = await DefaultCacheManager().getFileFromCache(_key(hash));
      if (info != null && await info.file.exists()) {
        final bytes = await info.file.readAsBytes();
        _remember(hash, bytes);
        return bytes;
      }
    } catch (_) {
      // Cache-Zugriff ist optional; im Fehlerfall normal nachladen.
    }

    final token = await auth.getAccessToken();
    final base64 = await api.fullImage(hash, token: token);
    if (base64 == null || base64.isEmpty) return null;

    final bytes = decodeBase64Image(base64);
    _remember(hash, bytes);

    try {
      await DefaultCacheManager().putFile(
        _key(hash),
        bytes,
        key: _key(hash),
        maxAge: const Duration(days: 365),
      );
    } catch (_) {
      // Disk-Cache ist optional.
    }

    return bytes;
  }

  void _remember(String hash, Uint8List bytes) {
    if (_memory.length >= _maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
    _memory[hash] = bytes;
  }

  String _key(String hash) => 'sinclear_media_$hash';
}
