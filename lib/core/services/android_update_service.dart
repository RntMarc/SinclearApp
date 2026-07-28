import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_update_info.dart';

class AndroidUpdateService {
  final String baseUrl;
  final Logger _log = Logger('AndroidUpdateService');

  AndroidUpdateService({required this.baseUrl});

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<AppUpdateInfo?> checkForUpdate() async {
    _log.info('checkForUpdate() called — baseUrl=$baseUrl');
    if (!isSupported) {
      _log.info('Platform not supported, skipping');
      return null;
    }

    final uri = Uri.parse('$baseUrl/app/version');
    _log.info('Requesting $uri');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      _log.info('Response ${response.statusCode}: ${response.body}');

      if (response.statusCode != 200) {
        throw ApiException(
          'Server returned ${response.statusCode}',
          response.body,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final updateInfo = AppUpdateInfo.fromJson(json);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.parse(packageInfo.buildNumber);

      _log.info(
        'Version check — server: ${updateInfo.versionCode} '
        '(${updateInfo.version}), local: $currentVersionCode '
        '(${packageInfo.version})',
      );

      if (updateInfo.versionCode > currentVersionCode) {
        _log.info('Update available!');
        return updateInfo;
      }

      _log.info('Already up-to-date');
      return null;
    } on TimeoutException {
      _log.warning('Request timed out after 15s');
      rethrow;
    } on SocketException catch (e) {
      _log.warning('Socket error: ${e.message}');
      rethrow;
    } catch (e, st) {
      _log.severe('Unexpected error', e, st);
      rethrow;
    }
  }

  Future<String> downloadApk(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    _log.info('downloadApk() — url=$downloadUrl');
    if (!isSupported) {
      throw StateError('APK download is only supported on Android');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/sinclear-update.apk');
    _log.info('Target file: ${file.path}');

    // Delete old update if present
    if (await file.exists()) {
      await file.delete();
      _log.info('Deleted previous update file');
    }

    final request = http.Request('GET', Uri.parse(downloadUrl));
    _log.info('Sending download request…');
    final response = await http.Client().send(request);

    _log.info(
      'Download response ${response.statusCode}, '
      'contentLength=${response.contentLength}',
    );

    if (response.statusCode != 200) {
      throw StateError('Download failed: ${response.statusCode}');
    }

    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;
    var lastLogPercent = 0;

    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        final percent = (receivedBytes * 100 / totalBytes).toInt();
        if (percent >= lastLogPercent + 10) {
          _log.info(
            'Download progress: $percent% ($receivedBytes/$totalBytes bytes)',
          );
          lastLogPercent = percent;
        }
        onProgress?.call(receivedBytes / totalBytes);
      }
    }
    await sink.close();

    final savedSize = await file.length();
    _log.info('Download complete — saved $savedSize bytes to ${file.path}');

    return file.path;
  }

  Future<void> installApk(String filePath) async {
    _log.info('installApk() — filePath=$filePath');

    final file = File(filePath);
    final exists = await file.exists();
    _log.info('File exists: $exists');

    if (!exists) {
      _log.severe('APK file not found at $filePath');
      throw StateError('APK file not found: $filePath');
    }

    final size = await file.length();
    _log.info('File size: $size bytes');

    if (size == 0) {
      _log.severe('APK file is empty');
      throw StateError('APK file is empty: $filePath');
    }

    _log.info(
      'Calling OpenFile.open() with type=application/vnd.android.package-archive',
    );
    final result = await OpenFile.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );

    _log.info(
      'OpenFile.open() returned — type=${result.type}, message=${result.message}',
    );

    if (result.type != ResultType.done) {
      _log.severe('OpenFile failed — ${result.message}');
      throw StateError('Failed to open APK: ${result.message}');
    }

    _log.info('OpenFile succeeded — intent dispatched');
  }
}

class ApiException implements Exception {
  final String message;
  final String? body;

  ApiException(this.message, [this.body]);

  @override
  String toString() =>
      'ApiException: $message${body != null ? ' ($body)' : ''}';
}
