import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/explore_models.dart';
import '../utils/cuisine_translations.dart';

class PlaceCard extends StatelessWidget {
  final ExplorePlace place;

  const PlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return DesignCard(
      onTap: () => context.go('/entdecken/${place.id}'),
      padding: EdgeInsets.all(tokens.spaceMd),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                place.category == 'gastronomy'
                    ? Icons.restaurant_rounded
                    : Icons.park_rounded,
                color: tokens.primary,
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignText(
                  place.name,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (place.avgRating != null) ...[
                SizedBox(width: tokens.spaceXs),
                Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: tokens.primary,
                ),
                const SizedBox(width: 2),
                DesignText(
                  place.avgRating!.toStringAsFixed(1),
                  style: DesignTextStyle.label,
                  color: tokens.primary,
                ),
              ],
            ],
          ),
          if (place.address != null) ...[
            SizedBox(height: tokens.spaceSm),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: tokens.textLow,
                ),
                SizedBox(width: tokens.spaceXs),
                Flexible(
                  child: DesignText(
                    place.address!,
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (place.cuisine != null) ...[
            SizedBox(height: tokens.spaceXs),
            DesignText(
              translateCuisine(place.cuisine),
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
          ],
        ],
      ),
    );
  }
}
