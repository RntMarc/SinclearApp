import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/pt_models.dart';

IconData _modeIcon(String mode) {
  switch (mode.toUpperCase()) {
    case 'RAIL':
    case 'TRAIN':
      return Icons.train_rounded;
    case 'BUS':
      return Icons.directions_bus_rounded;
    case 'TRAM':
      return Icons.tram_rounded;
    case 'SUBWAY':
      return Icons.subway_rounded;
    case 'WALK':
      return Icons.directions_walk_rounded;
    case 'FERRY':
      return Icons.directions_ferry_rounded;
    default:
      return Icons.directions_transit_rounded;
  }
}

class PtJourneyCard extends StatelessWidget {
  const PtJourneyCard({required this.journey, this.onTap, super.key});

  final PtSavedJourney journey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final mode = journey.legs.isNotEmpty ? journey.legs.first.mode : 'RAIL';

    return DesignCard(
      margin: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        0,
        tokens.spaceLg,
        tokens.spaceXs,
      ),
      padding: EdgeInsets.all(tokens.spaceMd),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(_modeIcon(mode), color: tokens.primary, size: 20),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignText(
                  '${journey.fromStationName} \u2192 ${journey.toStationName}',
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                ),
                SizedBox(height: tokens.spaceXs),
                DesignText(
                  '${formatDateTime(journey.departureTime)} \u2022 ${_formatDuration(journey.duration)}${journey.transfers > 0 ? ' \u2022 ${journey.transfers} Umstieg${journey.transfers == 1 ? '' : 'e'}' : ''}',
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: tokens.spaceMd),
            child: Icon(Icons.chevron_right_rounded, color: tokens.textLow),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}
