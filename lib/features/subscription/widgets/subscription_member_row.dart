import 'package:flutter/material.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../models/subscription_models.dart';

/// A compact member row for the subscription detail screen.
///
/// Maps a [SubscriptionParticipant] model onto catalog primitives
/// ([DesignAvatar], [DesignText]) and shows the payment status.
class SubscriptionMemberRow extends StatelessWidget {
  const SubscriptionMemberRow({
    super.key,
    required this.participant,
  });

  final SubscriptionParticipant participant;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
      child: Row(
        children: [
          DesignAvatar(
            name: participant.displayName,
            imageUrl: participant.userImage,
            size: 36,
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  participant.displayName,
                  style: DesignTextStyle.body,
                ),
                if (!participant.isUser)
                  DesignText(
                    'Nicht registriert',
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                  ),
              ],
            ),
          ),
          DesignText(
            participant.hasPaid ? 'Bezahlt' : 'Offen',
            style: DesignTextStyle.label,
            color: participant.hasPaid ? tokens.success : tokens.danger,
          ),
        ],
      ),
    );
  }
}
