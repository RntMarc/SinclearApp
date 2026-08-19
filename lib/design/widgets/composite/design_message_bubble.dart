import 'package:flutter/material.dart';

import '../../../core/utils/date_utils.dart';
import '../../theme/design_theme.dart';
import '../foundation/design_text.dart';

/// Chat-Sprachblase, die eine einzelne Nachricht darstellt.
///
/// Eigene Nachrichten liegen rechts (Primärfarbe), fremde links
/// (Oberflächenfarbe). Gelöschte Nachrichten zeigen einen Platzhalter.
/// [linkPreview] (z. B. eine URL-Vorschau) wird unter dem Text gerendert.
/// In Gruppenchats kann [senderName] gesetzt werden, um den Absendernamen
/// über dem Text anzuzeigen (bei eigenen Nachrichten wird er weggelassen).
class DesignMessageBubble extends StatelessWidget {
  /// Anzeigetext; bei [deleted] wird ein Platzhalter gezeigt.
  final String text;

  final bool isOwn;

  /// Zeitstempel, unterhalb der Blase angezeigt.
  final DateTime? time;

  final bool deleted;

  /// `true`, wenn die Nachricht nachträglich bearbeitet wurde.
  final bool edited;

  /// Optionaler Inhalt unter dem Text (z. B. `OgPreviewCard`).
  final Widget? linkPreview;

  /// Wird bei Long-Press auf die Blase ausgelöst (z. B. Bearbeiten/Löschen).
  final VoidCallback? onLongPress;

  /// `true`, wenn die Nachricht vom Gegenüber gelesen wurde
  /// (anderer `lastReadSeq` >= `seq`). Zeigt Doppelhaken an.
  final bool read;

  /// Absendername in Gruppenchats. Wird oberhalb des Texts angezeigt,
  /// aber nicht bei eigenen oder gelöschten Nachrichten.
  final String? senderName;

  const DesignMessageBubble({
    required this.text,
    this.isOwn = false,
    this.time,
    this.deleted = false,
    this.edited = false,
    this.linkPreview,
    this.onLongPress,
    this.read = false,
    this.senderName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final bg = isOwn ? tokens.primary : tokens.surfaceVariant;
    final fg = isOwn ? tokens.textOnPrimary : tokens.textHigh;

    final bubble = GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceSm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(tokens.radiusLg),
            topRight: Radius.circular(tokens.radiusLg),
            bottomLeft: Radius.circular(
              isOwn ? tokens.radiusLg : tokens.radiusSm,
            ),
            bottomRight: Radius.circular(
              isOwn ? tokens.radiusSm : tokens.radiusLg,
            ),
          ),
          boxShadow: isOwn ? tokens.glowShadow : tokens.surfaceShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deleted)
              DesignText(
                'Nachricht gelöscht',
                style: DesignTextStyle.label,
                color: isOwn
                    ? tokens.textOnPrimary.withValues(alpha: 0.7)
                    : tokens.textLow,
              )
            else ...[
              if (senderName != null && !isOwn)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.spaceXs),
                  child: DesignText(
                    senderName!,
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                  ),
                ),
              DesignText(text, style: DesignTextStyle.body, color: fg),
              if (edited)
                Padding(
                  padding: EdgeInsets.only(top: tokens.spaceXs),
                  child: DesignText(
                    'bearbeitet',
                    style: DesignTextStyle.label,
                    color: isOwn
                        ? tokens.textOnPrimary.withValues(alpha: 0.7)
                        : tokens.textLow,
                  ),
                ),
            ],
            if (linkPreview != null) ...[
              SizedBox(height: tokens.spaceSm),
              linkPreview!,
            ],
          ],
        ),
      ),
    );

    final time = this.time;
    return Column(
      crossAxisAlignment: isOwn
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        bubble,
        Padding(
          padding: EdgeInsets.only(
            top: tokens.spaceXs,
            left: tokens.spaceSm,
            right: tokens.spaceSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (time != null)
                DesignText(
                  formatTime(time),
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                ),
              if (isOwn && read) ...[
                SizedBox(width: tokens.spaceXs),
                Icon(Icons.done_all_rounded, size: 14, color: tokens.primary),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
