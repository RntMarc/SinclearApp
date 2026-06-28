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

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!isSupported) return null;

    final uri = Uri.parse('$baseUrl/app/version');
    developer.log(
      'Checking for update',
      name: 'AndroidUpdateService',
      error: 'URL: $uri',
    );

    try {
      final response = await http.get(uri).timeout(
            const Duration(seconds: 15),
          );

      developer.log(
        'Update check response',
        name: 'AndroidUpdateService',
        error: 'Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.statusCode != 200) {
        developer.log(
          'Update check failed',
          name: 'AndroidUpdateService',
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
        throw ApiException(
          'Server returned ${response.statusCode}',
          response.body,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final updateInfo = AppUpdateInfo.fromJson(json);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.parse(packageInfo.buildNumber);

      developer.log(
        'Version comparison',
        name: 'AndroidUpdateService',
        error:
            'Server: ${updateInfo.versionCode}, Local: $currentVersionCode',
      );

      if (updateInfo.versionCode > currentVersionCode) {
        return updateInfo;
      }
      return null;
    } on TimeoutException {
      developer.log(
        'Update check timed out',
        name: 'AndroidUpdateService',
      );
      rethrow;
    } on SocketException catch (e) {
      developer.log(
        'Update check socket error',
        name: 'AndroidUpdateService',
        error: e.message,
      );
      rethrow;
    } catch (e, st) {
      developer.log(
        'Update check error',
        name: 'AndroidUpdateService',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<String> downloadApk(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    if (!isSupported) {
      throw StateError('APK download is only supported on Android');
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/sinclear-update.apk');

    final request = http.Request('GET', Uri.parse(downloadUrl));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      throw StateError('Download failed: ${response.statusCode}');
    }

    final totalBytes = response.contentLength ?? 0;
    var receivedBytes = 0;

    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        onProgress?.call(receivedBytes / totalBytes);
      }
    }
    await sink.close();

    return file.path;
  }

  Future<void> installApk(String filePath) async {
    final file = File(filePath);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;

    developer.log(
      'Installing APK',
      name: 'AndroidUpdateService',
      error: 'Path: $filePath, Exists: $exists, Size: $size bytes',
    );

    if (!exists) {
      throw StateError('APK file not found: $filePath');
    }

    if (size == 0) {
      throw StateError('APK file is empty: $filePath');
    }

    final result = await OpenFile.open(
      filePath,
      type: 'application/vnd.android.package-archive',
    );

    developer.log(
      'OpenFile result',
      name: 'AndroidUpdateService',
      error: 'Type: ${result.type}, Message: ${result.message}',
    );

    if (result.type != ResultType.done) {
      throw StateError('Failed to open APK: ${result.message}');
    }
  }
}

class ApiException implements Exception {
  final String message;
  final String? body;

  ApiException(this.message, [this.body]);

  @override
  String toString() => 'ApiException: $message${body != null ? ' ($body)' : ''}';
}
