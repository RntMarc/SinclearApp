import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_update_info.dart';

class AndroidUpdateService {
  final String baseUrl;

  const AndroidUpdateService({required this.baseUrl});

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!isSupported) return null;

    try {
      final uri = Uri.parse('$baseUrl/app/version');
      final response = await http.get(uri).timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final updateInfo = AppUpdateInfo.fromJson(json);

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.parse(packageInfo.buildNumber);

      if (updateInfo.versionCode > currentVersionCode) {
        return updateInfo;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> downloadApk(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    if (!isSupported) {
      throw StateError('APK download is only supported on Android');
    }

    final permission = await Permission.requestInstallPackages.request();
    if (!permission.isGranted) {
      throw StateError('Install permission denied');
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
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      throw StateError('Failed to open APK: ${result.message}');
    }
  }
}
