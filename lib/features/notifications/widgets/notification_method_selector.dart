import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/primitives/design_badge.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../settings/models/notification_preference.dart';
import 'notification_method_info_sheet.dart';

/// Auswahl-Karte für die Zustell-Methode — dieselbe Karte in Setup und
/// Einstellungen. Jede Option erklärt sich über einen Info-Button.
class NotificationMethodSelector extends StatelessWidget {
  const NotificationMethodSelector({
    required this.selected,
    required this.onSelect,
    this.saving = false,
    super.key,
  });

  /// Aktuell gespeicherte Methode (markiert die Radio-Auswahl).
  final NotificationMethod selected;

  /// Wird beim Tippen auf eine wählbare Option ausgelöst.
  final ValueChanged<NotificationMethod> onSelect;

  /// Während des Setups: Radio-Icons durch einen Spinner ersetzen und Taps
  /// sperren.
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return DesignCard.list(
      children: [
        for (final method in NotificationMethodX.availableFor())
          _MethodTile(
            method: method,
            selected: selected == method,
            saving: saving,
            onSelect: onSelect,
          ),
        if (!kIsWeb && Platform.isAndroid)
          const _FcmTile(method: NotificationMethod.fcm),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.saving,
    required this.onSelect,
  });

  final NotificationMethod method;
  final bool selected;
  final bool saving;
  final ValueChanged<NotificationMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignListTile(
      leading: Icon(_icon(method), color: tokens.textHigh),
      title: method.label,
      subtitle: method.description,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InfoButton(method: method),
          SizedBox(width: tokens.spaceSm),
          if (saving)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: tokens.primary,
              ),
            )
          else
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? tokens.primary : tokens.textLow,
            ),
        ],
      ),
      onTap: saving ? null : () => onSelect(method),
    );
  }
}

class _FcmTile extends StatelessWidget {
  const _FcmTile({required this.method});

  final NotificationMethod method;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignListTile(
      leading: Icon(Icons.cloud_rounded, color: tokens.textHigh),
      title: method.label,
      subtitle: 'Google Firebase Cloud Messaging – geplant',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InfoButton(method: method),
          SizedBox(width: tokens.spaceSm),
          const DesignBadge(label: 'Bald verfügbar'),
        ],
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.method});

  final NotificationMethod method;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Tooltip(
      message: 'Wie funktioniert ${method.label}?',
      child: PressScale(
        onTap: () => showNotificationMethodInfoSheet(context, method),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceXs),
          child: Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: tokens.textLow,
          ),
        ),
      ),
    );
  }
}

IconData _icon(NotificationMethod method) {
  return switch (method) {
    NotificationMethod.polling => Icons.sync_rounded,
    NotificationMethod.unifiedPush => Icons.push_pin_rounded,
    NotificationMethod.fcm => Icons.cloud_rounded,
  };
}
