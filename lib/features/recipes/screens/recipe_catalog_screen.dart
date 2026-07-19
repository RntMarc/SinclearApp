import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_card_chip_group.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../models/recipes_models.dart';

class RecipeCatalogScreen extends StatefulWidget {
  const RecipeCatalogScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<RecipeCatalogScreen> createState() => _RecipeCatalogScreenState();
}

class _RecipeCatalogScreenState extends State<RecipeCatalogScreen> {
  final List<RecipeListItem> _allRecipes = [];
  String? _selectedCategory;
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _selectedCategory = widget.initialCategory;
      _loadRecipes();
    }
  }

  List<RecipeListItem> get _filtered => _selectedCategory == null
      ? _allRecipes
      : _allRecipes.where((r) => r.category == _selectedCategory).toList();

  Future<void> _loadRecipes() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recipes = AppScope.of(context).recipes;
      final response = await recipes.list(
        sort: 'created_desc',
        page: _page,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _allRecipes.addAll(response.data);
        _hasMore = response.data.length >= 20;
        _page++;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load recipe catalog', error: e, stackTrace: st);
      if (kDebugMode) {
        debugPrint('[recipe_catalog] _loadRecipes error: $e');
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Rezepte konnten nicht geladen werden.';
      });
    }
  }

  Widget _recipeCard(RecipeListItem recipe, DesignTokens tokens) {
    final icon = recipeCategoryIcons[recipe.category] ?? '🍴';
    return DesignCard(
      margin: EdgeInsets.only(bottom: tokens.spaceMd),
      useGlass: false,
      onTap: () => context.go('/rezepte/${recipe.id}'),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceSm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: Container(
                width: 48,
                height: 48,
                color: tokens.surfaceVariant,
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(
                      fontSize: 20,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Column(
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
                    recipe.categoryLabel,
                    style: DesignTextStyle.label,
                    color: tokens.textLow,
                  ),
                ],
              ),
            ),
            if (recipe.avgRating != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 14, color: tokens.primary),
                  SizedBox(width: tokens.spaceXs),
                  DesignText(
                    recipe.avgRating!.toStringAsFixed(1),
                    style: DesignTextStyle.label,
                    color: tokens.textHigh,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final filtered = _filtered;
    final categoryKeys = recipeCategories.keys.toList();
    final initialScrollIndex = _selectedCategory != null
        ? categoryKeys.indexOf(_selectedCategory!)
        : null;

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: 'Alle Rezepte',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRecipes,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: tokens.spaceXxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: tokens.spaceSm),
                      child: DesignCardChipGroup(
                        initialScrollIndex: initialScrollIndex,
                        items: [
                          for (final key in recipeCategories.keys)
                            DesignCardChipItem(
                              icon: recipeCategoryIcons[key] ?? '🍴',
                              label: recipeCategories[key]!,
                              selected: _selectedCategory == key,
                              onTap: () => setState(() {
                                _selectedCategory = _selectedCategory == key
                                    ? null
                                    : key;
                              }),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.spaceLg,
                        tokens.spaceXl,
                        tokens.spaceLg,
                        tokens.spaceSm,
                      ),
                      child: DesignText(
                        _selectedCategory != null
                            ? recipeCategories[_selectedCategory] ?? 'Rezepte'
                            : 'Alle Rezepte',
                        style: DesignTextStyle.title,
                      ),
                    ),
                    if (_loading && _allRecipes.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(tokens.spaceLg),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: tokens.primary,
                          ),
                        ),
                      )
                    else if (_error != null && _allRecipes.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(tokens.spaceLg),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 24,
                                color: tokens.danger,
                              ),
                              SizedBox(height: tokens.spaceMd),
                              DesignText(_error!),
                              SizedBox(height: tokens.spaceSm),
                              DesignButton(
                                label: 'Erneut versuchen',
                                variant: DesignButtonVariant.outlined,
                                onPressed: _loadRecipes,
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (filtered.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(tokens.spaceLg),
                        child: Center(
                          child: DesignText(
                            'Keine Rezepte in dieser Kategorie.',
                            color: tokens.textLow,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceLg,
                        ),
                        child: Column(
                          children: [
                            for (final recipe in filtered)
                              _recipeCard(recipe, tokens),
                            if (_loading)
                              Padding(
                                padding: EdgeInsets.all(tokens.spaceMd),
                                child: CircularProgressIndicator(
                                  color: tokens.primary,
                                ),
                              )
                            else if (_hasMore)
                              Padding(
                                padding: EdgeInsets.only(top: tokens.spaceMd),
                                child: DesignButton(
                                  label: 'Mehr laden',
                                  variant: DesignButtonVariant.text,
                                  onPressed: _loadRecipes,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
