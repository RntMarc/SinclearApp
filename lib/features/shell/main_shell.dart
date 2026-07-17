import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/di/app_scope.dart';
import '../../core/models/app_update_info.dart';
import '../../core/services/android_update_service.dart';
import '../update/update_dialog.dart';
import 'widgets/shell_widgets.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _updateChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_updateChecked) {
      _updateChecked = true;
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    developer.log('MainShell._checkForUpdate — kReleaseMode=$kReleaseMode');
    if (!kReleaseMode) return;
    final androidUpdate = AppScope.of(context).androidUpdate;
    developer.log('isSupported=${androidUpdate.isSupported}');
    if (!androidUpdate.isSupported) return;

    AppUpdateInfo? updateInfo;
    try {
      updateInfo = await androidUpdate.checkForUpdate();
    } catch (e) {
      developer.log('Update check threw: $e');
    }

    developer.log('updateInfo=$updateInfo, mounted=$mounted');
    if (!mounted || updateInfo == null) return;

    await UpdateDialog.show(
      context,
      updateInfo: updateInfo,
      onDownload: (dialog) =>
          _downloadAndInstall(dialog, androidUpdate, updateInfo!),
    );
  }

  Future<void> _downloadAndInstall(
    UpdateDialogState dialog,
    AndroidUpdateService service,
    AppUpdateInfo info,
  ) async {
    developer.log('=== Download & Install flow started ===');
    try {
      developer.log('Starting download from ${info.downloadUrl}');
      final filePath = await service.downloadApk(
        info.downloadUrl,
        onProgress: (p) => dialog.setProgress(p),
      );
      developer.log('Download done, filePath=$filePath');

      if (!mounted) {
        developer.log('Widget unmounted before pop, aborting');
        return;
      }

      developer.log('Popping dialog');
      Navigator.pop(context, true);
      await Future<void>.delayed(Duration.zero);

      developer.log('Calling installApk…');
      await service.installApk(filePath);
      developer.log('installApk returned successfully');
    } catch (e) {
      developer.log('ERROR in _downloadAndInstall: $e');
      dialog.setError('Download fehlgeschlagen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 600;

    if (isDesktop) {
      return ShellDesktop(child: widget.child);
    }
    return ShellMobile(child: widget.child);
  }
}
