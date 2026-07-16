import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../models/recipes_models.dart';

class RecipeCard extends StatelessWidget {
  final RecipeListItem recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final icon = recipeCategoryIcons[recipe.category] ?? '🍴';

    return DesignCard(
      useGlass: false,
      onTap: () => context.go('/rezepte/${recipe.id}'),
      child: Row(
        children: [
          if (recipe.image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusSm),
              child: Image.network(
                recipe.image!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _FallbackImage(icon: icon, tokens: tokens),
              ),
            )
          else
            _FallbackImage(icon: icon, tokens: tokens),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DesignText(
                  recipe.title,
                  style: DesignTextStyle.body,
                  color: tokens.textHigh,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: tokens.spaceXs),
                DesignText(
                  recipe.categoryLabel,
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                ),
                if (recipe.avgRating != null) ...[
                  SizedBox(height: tokens.spaceXs),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: tokens.primary),
                      SizedBox(width: tokens.spaceXs),
                      DesignText(
                        recipe.avgRating!.toStringAsFixed(1),
                        style: DesignTextStyle.label,
                        color: tokens.textHigh,
                      ),
                      SizedBox(width: tokens.spaceXs),
                      DesignText(
                        '(${recipe.ratingCount})',
                        style: DesignTextStyle.label,
                        color: tokens.textLow,
                      ),
                    ],
                  ),
                ],
                if (recipe.dietaryTags != null && recipe.dietaryTags!.isNotEmpty) ...[
                  SizedBox(height: tokens.spaceXs),
                  DesignText(
                    recipe.dietaryTags!,
                    style: DesignTextStyle.label,
                    color: tokens.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  final String icon;
  final DesignTokens tokens;

  const _FallbackImage({required this.icon, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: tokens.surfaceVariant,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
      child: Center(
        child: Text(icon, style: const TextStyle(fontSize: 28, decoration: TextDecoration.none)),
      ),
    );
  }
}
