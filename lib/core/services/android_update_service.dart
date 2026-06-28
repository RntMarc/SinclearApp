import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_update_info.dart';

class AndroidUpdateService {
  final String baseUrl;

  const AndroidUpdateService({required this.baseUrl});

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _log(String msg, {Object? error, StackTrace? st}) {
    developer.log(
      msg,
      name: 'AndroidUpdateService',
      error: error,
      stackTrace: st,
    );
  }

  Future<AppUpdateInfo?> checkForUpdate() async {
    _log('checkForUpdate() called — baseUrl=$baseUrl');
    if (!isSupported) {
      _log('Platform not supported, skipping');
      return null;
    }

    final uri = Uri.parse('$baseUrl/app/version');
    _log('Requesting $uri');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      _log('Response ${response.statusCode}: ${response.body}');

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

      _log(
        'Version check — server: ${updateInfo.versionCode} '
        '(${updateInfo.version}), local: $currentVersionCode '
        '(${packageInfo.version})',
      );

      if (updateInfo.versionCode > currentVersionCode) {
        _log('Update available!');
        return updateInfo;
      }

      _log('Already up-to-date');
      return null;
    } on TimeoutException {
      _log('Request timed out after 15s');
      rethrow;
    } on SocketException catch (e) {
      _log('Socket error: ${e.message}');
      rethrow;
    } catch (e, st) {
      _log('Unexpected error', error: e, st: st);
      rethrow;
    }
  }

  Future<String> downloadApk(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    _log('downloadApk() — url=$downloadUrl');
    if (!isSupported) {
      throw StateError('APK download is only supported on Android');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/sinclear-update.apk');
    _log('Target file: ${file.path}');

    // Delete old update if present
    if (await file.exists()) {
      await file.delete();
      _log('Deleted previous update file');
    }

    final request = http.Request('GET', Uri.parse(downloadUrl));
    _log('Sending download request…');
    final response = await http.Client().send(request);

    _log(
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
          _log(
            'Download progress: $percent% ($receivedBytes/$totalBytes bytes)',
          );
          lastLogPercent = percent;
        }
        onProgress?.call(receivedBytes / totalBytes);
      }
    }
    await sink.close();

    final savedSize = await file.length();
    _log('Download complete — saved $savedSize bytes to ${file.path}');

    return file.path;
  }

  Future<void> installApk(String filePath) async {
    _log('installApk() — filePath=$filePath');

    final file = File(filePath);
    final exists = await file.exists();
    _log('File exists: $exists');

    if (!exists) {
      _log('ERROR: APK file not found at $filePath');
      throw StateError('APK file not found: $filePath');
    }

    final size = await file.length();
    _log('File size: $size bytes');

    if (size == 0) {
      _log('ERROR: APK file is empty');
      throw StateError('APK file is empty: $filePath');
    }

    _log(
      'Calling OpenFile.open() with type=application/vnd.android.package-archive',
    );
    final result = await OpenFile.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );

    _log(
      'OpenFile.open() returned — type=${result.type}, message=${result.message}',
    );

    if (result.type != ResultType.done) {
      _log('ERROR: OpenFile failed — ${result.message}');
      throw StateError('Failed to open APK: ${result.message}');
    }

    _log('OpenFile succeeded — intent dispatched');
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
