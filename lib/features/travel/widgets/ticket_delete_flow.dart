import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';

/// Confirms and deletes a `user`-type ticket via the self-service endpoint.
///
/// Admin tickets (`trip`/`event`) are group-scoped and only manageable by
/// admins, so they never pass through here. Returns `true` when the ticket
/// was deleted, `false` when the user cancelled or the request failed.
Future<bool> deleteUserTicketFlow({
  required BuildContext context,
  required TravelService service,
  required TravelEventTicket ticket,
}) async {
  final tokens = DesignTheme.of(context);
  final confirmed = await showDesignSheet<bool>(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DesignText(
          'Ticket löschen',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignText(
          'Möchtest du dieses Ticket wirklich löschen?',
          style: DesignTextStyle.body,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceXl),
        DesignButton(
          variant: DesignButtonVariant.filled,
          label: 'Löschen',
          fullWidth: true,
          onPressed: () => Navigator.pop(context, true),
        ),
        SizedBox(height: tokens.spaceSm),
        DesignButton(
          variant: DesignButtonVariant.outlined,
          label: 'Abbrechen',
          fullWidth: true,
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await service.deleteUserTicket(ticket.id);
    return true;
  } catch (e) {
    developer.log('Delete ticket failed', error: e);
    return false;
  }
}
