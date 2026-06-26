import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../models/explore_models.dart';

class PlaceCard extends StatelessWidget {
  final ExplorePlace place;

  const PlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return GestureDetector(
      onTap: () => context.go('/entdecken/${place.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  place.category == 'gastronomy'
                      ? CupertinoIcons.square_grid_2x2
                      : CupertinoIcons.leaf_arrow_circlepath,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.textStyle.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (place.avgRating != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.star_fill,
                    size: 16,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    place.avgRating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
            if (place.address != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.location,
                    size: 16,
                    color: theme.textTheme.textStyle.color
                        ?.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      place.address!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.textStyle.color
                            ?.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (place.cuisine != null) ...[
              const SizedBox(height: 4),
              Text(
                place.cuisine!,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.textStyle.color
                      ?.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
