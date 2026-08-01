import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/moderation_models.dart';

/// Öffnet das Formular zum Melden oder Beantragen.
///
/// [isOwn] steuert die angebotenen Anfragetypen: Eigene Inhalte können nicht
/// gemeldet (`cannot_report_own`), fremde nicht zur Löschung beantragt werden
/// (`cannot_request_deletion_foreign`). Liefert `true`, wenn die Anfrage
/// erfolgreich übermittelt wurde.
Future<bool> showModerationRequestSheet(
  BuildContext context, {
  required ModerationObjectType objectType,
  required String objectId,
  required String objectName,
  required bool isOwn,
}) async {
  final submitted = await showDesignSheet<bool>(
    context: context,
    child: ModerationRequestSheet(
      objectType: objectType,
      objectId: objectId,
      objectName: objectName,
      isOwn: isOwn,
    ),
  );
  return submitted ?? false;
}

class ModerationRequestSheet extends StatefulWidget {
  final ModerationObjectType objectType;
  final String objectId;
  final String objectName;
  final bool isOwn;

  const ModerationRequestSheet({
    super.key,
    required this.objectType,
    required this.objectId,
    required this.objectName,
    required this.isOwn,
  });

  @override
  State<ModerationRequestSheet> createState() => _ModerationRequestSheetState();
}

class _ModerationRequestSheetState extends State<ModerationRequestSheet> {
  final _messageController = TextEditingController();
  late ModerationRequestType _type = widget.isOwn
      ? ModerationRequestType.deletion
      : ModerationRequestType.report;
  bool _submitting = false;
  String? _error;

  /// Anfragetypen, die für dieses Objekt erlaubt sind.
  List<ModerationRequestType> get _availableTypes => [
    if (!widget.isOwn) ModerationRequestType.report,
    if (widget.isOwn) ModerationRequestType.deletion,
    ModerationRequestType.other,
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Bitte beschreibe dein Anliegen.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await AppScope.of(context).moderation.create(
        requestType: _type,
        objectType: widget.objectType,
        objectId: widget.objectId,
        message: message,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      developer.log('Moderation request failed', name: 'moderation', error: e);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _errorMessage(e.errorCode);
      });
    } catch (e) {
      developer.log('Moderation request failed', name: 'moderation', error: e);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Übermittlung fehlgeschlagen. Bitte erneut versuchen.';
      });
    }
  }

  String _errorMessage(String code) {
    switch (code) {
      case 'message_required':
        return 'Bitte beschreibe dein Anliegen.';
      case 'invalid_request_type':
        return 'Ungültiger Anfragetyp.';
      case 'invalid_object_type':
        return 'Ungültiger Objekttyp.';
      case 'object_not_found':
        return 'Das Objekt wurde nicht gefunden.';
      case 'cannot_report_own':
        return 'Eigene Inhalte können nicht gemeldet werden.';
      case 'cannot_request_deletion_foreign':
        return 'Fremde Inhalte können nicht zur Löschung beantragt werden.';
      default:
        return 'Übermittlung fehlgeschlagen. Bitte erneut versuchen.';
    }
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
            _type == ModerationRequestType.report
                ? 'Inhalt melden'
                : _type == ModerationRequestType.deletion
                ? 'Löschung beantragen'
                : 'Anfrage stellen',
            style: DesignTextStyle.title,
            color: tokens.textHigh,
          ),
          SizedBox(height: tokens.spaceXs),
          DesignText(
            '${widget.objectType.label}: ${widget.objectName}',
            style: DesignTextStyle.body,
            color: tokens.textLow,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: tokens.spaceLg),
          Wrap(
            spacing: tokens.spaceSm,
            runSpacing: tokens.spaceXs,
            children: _availableTypes
                .map(
                  (t) => DesignChip(
                    label: t.label,
                    selected: _type == t,
                    onTap: () => setState(() => _type = t),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: tokens.spaceMd),
          DesignTextField(
            controller: _messageController,
            hint: _type == ModerationRequestType.report
                ? 'Was ist problematisch an diesem Inhalt?'
                : _type == ModerationRequestType.deletion
                ? 'Warum soll der Inhalt gelöscht werden?'
                : 'Dein Anliegen...',
            maxLines: 4,
            maxLength: 2000,
          ),
          if (_error != null) ...[
            SizedBox(height: tokens.spaceSm),
            DesignText(
              _error!,
              style: DesignTextStyle.label,
              color: tokens.danger,
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          Row(
            children: [
              Expanded(
                child: DesignButton(
                  variant: DesignButtonVariant.outlined,
                  label: 'Abbrechen',
                  onPressed: _submitting
                      ? null
                      : () => Navigator.pop(context, false),
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignButton(
                  variant: DesignButtonVariant.filled,
                  label: 'Senden',
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
