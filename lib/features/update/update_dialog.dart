import 'package:flutter/material.dart';

import '../../core/models/app_update_info.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final Future<void> Function(UpdateDialogState dialog) onDownload;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onDownload,
  });

  static Future<bool?> show(
    BuildContext context, {
    required AppUpdateInfo updateInfo,
    required Future<void> Function(UpdateDialogState dialog) onDownload,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(
        updateInfo: updateInfo,
        onDownload: onDownload,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => UpdateDialogState();
}

class UpdateDialogState extends State<UpdateDialog> {
  double? _progress;
  String? _error;
  bool _downloading = false;

  void setProgress(double value) {
    setState(() => _progress = value);
  }

  void setError(String message) {
    setState(() {
      _error = message;
      _downloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Update verfügbar'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${widget.updateInfo.version}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Was ist neu:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.updateInfo.changelog.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(entry)),
                  ],
                ),
              ),
            ),
            if (_downloading) ...[
              const SizedBox(height: 16),
              if (_progress != null)
                Column(
                  children: [
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progress! * 100).toInt()}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                )
              else
                const LinearProgressIndicator(),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Später'),
          ),
        if (!_downloading)
          FilledButton(
            onPressed: () async {
              setState(() => _downloading = true);
              await widget.onDownload(this);
            },
            child: const Text('Herunterladen'),
          ),
      ],
    );
  }
}
