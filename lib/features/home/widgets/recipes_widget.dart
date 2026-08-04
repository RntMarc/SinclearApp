import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/press_scale.dart';
import '../../recipes/models/recipes_models.dart';
import '../../recipes/services/recipes_service.dart';
import '../dashboard_widget.dart';
import '../dashboard_widget_spec.dart';

/// Anzeige-Datensatz eines Rezepts im Dashboard-Widget.
class RecipeRow implements DashboardRow {
  final String id;
  final String title;
  final String category;
  final String? image;
  final double? avgRating;
  final String createdAt;

  const RecipeRow({
    required this.id,
    required this.title,
    required this.category,
    this.image,
    this.avgRating,
    required this.createdAt,
  });

  factory RecipeRow.fromListItem(RecipeListItem recipe) {
    return RecipeRow(
      id: recipe.id,
      title: recipe.title,
      category: recipe.category,
      image: recipe.image,
      avgRating: recipe.avgRating,
      createdAt: recipe.createdAt,
    );
  }

  factory RecipeRow.fromJson(Map<String, dynamic> json) {
    return RecipeRow(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      image: json['image'] as String?,
      avgRating: (json['avgRating'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'image': image,
    'avgRating': avgRating,
    'createdAt': createdAt,
  };
}

/// Widget „Neue Rezepte“ – die neuesten Rezepte, sortiert nach Erstellung.
class RecipesWidgetSpec extends DashboardWidgetSpec {
  RecipesWidgetSpec(this._service);

  final RecipesService _service;

  @override
  DashboardWidgetType get type => DashboardWidgetType.recipes;

  @override
  String get listRoute => '/rezepte';

  @override
  Future<List<DashboardRow>> fetch(int count) async {
    final response = await _service.list(
      sort: 'created_desc',
      page: 1,
      limit: count,
    );
    return [for (final recipe in response.data) RecipeRow.fromListItem(recipe)];
  }

  @override
  DashboardRow rowFromJson(Map<String, dynamic> json) =>
      RecipeRow.fromJson(json);

  @override
  Widget rowBuilder(
    BuildContext context,
    DashboardRow row,
    VoidCallback? onTap,
  ) {
    final recipe = row as RecipeRow;
    final tokens = DesignTheme.of(context);
    return PressScale(
      onTap: onTap,
      child: Row(
        children: [
          _Thumb(image: recipe.image),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  recipe.avgRating != null
                      ? '${recipe.category} · ★ ${recipe.avgRating!.toStringAsFixed(1)}'
                      : recipe.category,
                  style: DesignTextStyle.label,
                  color: tokens.textLow,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onRowTap(BuildContext context, DashboardRow row) {
    context.go('/rezepte/${(row as RecipeRow).id}');
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final url = image;
    if (url == null || url.isEmpty) {
      return _fallback(tokens);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(tokens),
      ),
    );
  }

  Widget _fallback(DesignTokens tokens) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: tokens.surfaceVariant,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Icon(Icons.restaurant_rounded, size: 18, color: tokens.primary),
    );
  }
}
