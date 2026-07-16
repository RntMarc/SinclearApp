import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_scope.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_card.dart';
import '../../../design/widgets/primitives/design_card_chip_group.dart';
import '../models/recipes_models.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  List<RecipeListItem> _recentRecipes = [];
  List<RecipeListItem> _bookmarks = [];
  bool _loadingRecent = true;
  bool _loadingBookmarks = true;
  String? _recentError;
  String? _bookmarksError;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadRecent();
      _loadBookmarks();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadRecent() async {
    setState(() {
      _loadingRecent = true;
      _recentError = null;
    });
    try {
      final recipes = AppScope.of(context).recipes;
      final response = await recipes.list(sort: 'created_desc', limit: 10);
      if (!mounted) return;
      setState(() {
        _recentRecipes = response.data;
        _loadingRecent = false;
      });
    } catch (e, st) {
      developer.log('Failed to load recent recipes', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingRecent = false;
        _recentError = 'Rezepte konnten nicht geladen werden.';
      });
    }
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _loadingBookmarks = true;
      _bookmarksError = null;
    });
    try {
      final recipes = AppScope.of(context).recipes;
      final response = await recipes.getBookmarks(limit: 10);
      if (!mounted) return;
      setState(() {
        _bookmarks = response.data;
        _loadingBookmarks = false;
      });
    } catch (e, st) {
      developer.log('Failed to load bookmarks', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingBookmarks = false;
        _bookmarksError = 'Lesezeichen konnten nicht geladen werden.';
      });
    }
  }

  Widget _recipeThumb(RecipeListItem recipe, DesignTokens tokens, double size) {
    final icon = recipeCategoryIcons[recipe.category] ?? '🍴';
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.surfaceVariant,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Center(
        child: Text(
          icon,
          style: TextStyle(
            fontSize: size * 0.42,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
    final image = recipe.image;
    if (image == null) return fallback;
    if (image.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Image.network(
          image,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }
    try {
      final bytes = image.startsWith('data:')
          ? base64Decode(image.split(',').last)
          : base64Decode(image);
      return ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    } catch (_) {
      return fallback;
    }
  }

  Widget _recipeTile(RecipeListItem recipe, DesignTokens tokens) {
    return DesignCard(
      margin: EdgeInsets.only(bottom: tokens.spaceMd),
      useGlass: false,
      onTap: () => context.go('/rezepte/${recipe.id}'),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceSm),
        child: Row(
          children: [
            _recipeThumb(recipe, tokens, 64),
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
                  if (recipe.avgRating != null) ...[
                    SizedBox(height: tokens.spaceXs),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: tokens.primary,
                        ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionError(
    String message,
    VoidCallback onRetry,
    DesignTokens tokens,
  ) {
    return DesignCard(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 24, color: tokens.danger),
              SizedBox(height: tokens.spaceMd),
              DesignText(message),
              SizedBox(height: tokens.spaceSm),
              DesignButton(
                label: 'Erneut versuchen',
                variant: DesignButtonVariant.outlined,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: tokens.spaceXxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesignCardChipGroup(
                  items: [
                    for (final key in recipeCategories.keys)
                      DesignCardChipItem(
                        icon: recipeCategoryIcons[key] ?? '🍴',
                        label: recipeCategories[key]!,
                        onTap: () => context.go('/rezepte/kategorie/$key'),
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceLg,
                    tokens.spaceXl,
                    tokens.spaceLg,
                    tokens.spaceSm,
                  ),
                  child: Row(
                    children: [
                      DesignText(
                        'Neueste Rezepte',
                        style: DesignTextStyle.title,
                      ),
                      const Spacer(),
                      if (_recentRecipes.isNotEmpty)
                        DesignButton(
                          label: 'Alle',
                          variant: DesignButtonVariant.text,
                          onPressed: () => context.go('/rezepte/alle'),
                        ),
                    ],
                  ),
                ),
                if (_loadingRecent)
                  Padding(
                    padding: EdgeInsets.all(tokens.spaceLg),
                    child: Center(
                      child: CircularProgressIndicator(color: tokens.primary),
                    ),
                  )
                else if (_recentError != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
                    child: _sectionError(_recentError!, _loadRecent, tokens),
                  )
                else if (_recentRecipes.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(tokens.spaceLg),
                    child: Center(
                      child: DesignText(
                        'Noch keine Rezepte vorhanden.',
                        color: tokens.textLow,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
                    child: Column(
                      children: [
                        for (final recipe in _recentRecipes)
                          _recipeTile(recipe, tokens),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: tokens.spaceLg),
                  child: Center(
                    child: DesignButton(
                      label: 'In allen Rezepten stöbern',
                      variant: DesignButtonVariant.text,
                      onPressed: () => context.go('/rezepte/alle'),
                    ),
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
                    'Lesezeichen',
                    style: DesignTextStyle.title,
                  ),
                ),
                if (_loadingBookmarks)
                  Padding(
                    padding: EdgeInsets.all(tokens.spaceLg),
                    child: Center(
                      child: CircularProgressIndicator(color: tokens.primary),
                    ),
                  )
                else if (_bookmarksError != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
                    child: _sectionError(
                      _bookmarksError!,
                      _loadBookmarks,
                      tokens,
                    ),
                  )
                else if (_bookmarks.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(tokens.spaceLg),
                    child: Center(
                      child: DesignText(
                        'Noch keine Lesezeichen vorhanden.',
                        color: tokens.textLow,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
                    child: Column(
                      children: [
                        for (final recipe in _bookmarks)
                          _recipeTile(recipe, tokens),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: tokens.spaceLg,
            right: tokens.spaceLg,
            child: DesignIconButton(
              icon: Icons.add_rounded,
              onPressed: () => context.go('/rezepte/neu'),
            ),
          ),
        ],
      ),
    );
  }
}
