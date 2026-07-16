import 'package:flutter/material.dart';

import '../../core/models/app_update_info.dart';
import '../../design/theme/design_theme.dart';
import '../../design/widgets/composite/design_bottom_sheet.dart';
import '../../design/widgets/foundation/design_text.dart';
import '../../design/widgets/primitives/design_button.dart';

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
    return showDesignSheet<bool>(
      context: context,
      child: UpdateDialog(
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
    final tokens = DesignTheme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesignText(
            'Update verfügbar',
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceMd),
          DesignText(
            'Version ${widget.updateInfo.version}',
            style: DesignTextStyle.body,
            color: tokens.primary,
          ),
          SizedBox(height: tokens.spaceMd),
          DesignText(
            'Was ist neu:',
            style: DesignTextStyle.body,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceSm),
          ...widget.updateInfo.changelog.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignText('• ', style: DesignTextStyle.body, color: tokens.textHigh),
                  Expanded(
                    child: DesignText(
                      entry,
                      style: DesignTextStyle.body,
                      color: tokens.textHigh,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_downloading) ...[
            SizedBox(height: tokens.spaceMd),
            if (_progress != null)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    color: tokens.primary,
                    backgroundColor: tokens.surfaceVariant,
                  ),
                  SizedBox(height: tokens.spaceSm),
                  DesignText(
                    '${(_progress! * 100).toInt()}%',
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                  ),
                ],
              )
            else
              LinearProgressIndicator(
                color: tokens.primary,
                backgroundColor: tokens.surfaceVariant,
              ),
          ],
          if (_error != null) ...[
            SizedBox(height: tokens.spaceMd),
            DesignText(
              _error!,
              style: DesignTextStyle.body,
              color: tokens.danger,
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          if (!_downloading)
            Row(
              children: [
                Expanded(
                  child: DesignButton(
                    variant: DesignButtonVariant.outlined,
                    label: 'Später',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: DesignButton(
                    variant: DesignButtonVariant.filled,
                    label: 'Herunterladen',
                    onPressed: () async {
                      setState(() => _downloading = true);
                      await widget.onDownload(this);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
