import 'package:flutter/material.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_poll_card.dart';
import '../models/poll_models.dart';

/// Icon je Umfrageart.
IconData pollTypeIcon(PollType type) => switch (type) {
  PollType.form => Icons.assignment_rounded,
  PollType.appointment => Icons.event_available_rounded,
  PollType.vote => Icons.how_to_vote_rounded,
};

/// Dünner Feature-Adapter: bildet ein [Poll]-Modell auf [DesignPollCard] ab.
class PollCard extends StatelessWidget {
  const PollCard({
    required this.poll,
    required this.hasUnread,
    this.onTap,
    super.key,
  });

  final Poll poll;
  final bool hasUnread;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final closesAt = poll.closesAt;
    final deadline = closesAt == null
        ? null
        : 'Frist: ${formatDateTimeInZone(closesAt, AppScope.of(context).timeZones.effective)}';

    return DesignPollCard(
      title: poll.title,
      typeLabel: poll.type.label,
      typeIcon: pollTypeIcon(poll.type),
      statusLabel: poll.status.label,
      creatorLabel: poll.creatorDisplayName,
      deadlineLabel: deadline,
      closed: poll.isClosed,
      pulseColor: hasUnread ? tokens.accentA : null,
      onTap: onTap,
    );
  }
}
